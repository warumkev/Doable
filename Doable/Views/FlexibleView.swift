// FlexibleView.swift
// Utility to wrap views in lines (like a flow layout)
import SwiftUI

struct FlexibleView<Data: Collection, Content: View>: View where Data.Element: Hashable {
    let data: Data
    let spacing: CGFloat
    let alignment: HorizontalAlignment
    let content: (Data.Element) -> Content

    @State private var totalHeight: CGFloat = .zero

    var body: some View {
        VStack(alignment: alignment, spacing: spacing) {
            GeometryReader { geometry in
                self.generateContent(in: geometry)
            }
        }
        .frame(height: totalHeight)
    }

    private func generateContent(in geometry: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var rows: [[Data.Element]] = [[]]

        for item in data {
            let itemSize = CGSize(width: 80, height: 28) // Estimate for chip size
            if width + itemSize.width > geometry.size.width {
                rows.append([item])
                width = itemSize.width
            } else {
                rows[rows.count - 1].append(item)
                width += itemSize.width + spacing
            }
        }

        DispatchQueue.main.async {
            self.totalHeight = CGFloat(rows.count) * (28 + spacing)
        }

        return VStack(alignment: alignment, spacing: spacing) {
            ForEach(rows, id: \ .self) { row in
                HStack(spacing: spacing) {
                    ForEach(row, id: \ .self) { item in
                        content(item)
                    }
                }
            }
        }
    }
}