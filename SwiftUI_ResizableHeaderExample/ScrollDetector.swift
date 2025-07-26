//
//  ScrollDetector.swift
//  SwiftUI_ResizableHeaderExample
//
//  Created by cano on 2025/07/26.
//

import SwiftUI

/// SwiftUI の ScrollView 内部から UIScrollView を取り出し、スクロールのオフセット・速度を検出するビュー
struct ScrollDetector: UIViewRepresentable {
    /// スクロール中の位置（Yオフセット）を返すコールバック
    var onScroll: (CGFloat) -> ()

    /// ドラッグ終了時の位置と速度（オフセット, Y方向の速度）を返すコールバック
    var onDraggingEnd: (CGFloat, CGFloat) -> ()
    
    // Coordinator（UIScrollViewDelegate を保持）
    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
    
    // 空の UIView を生成（SwiftUIに挿入されるが、機能的な目的はデリゲート用）
    func makeUIView(context: Context) -> UIView {
        return UIView()
    }
    
    // UIView が更新されたときに UIScrollView を検出し、デリゲートを設定
    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            // SwiftUI の ScrollView の構造を辿って UIScrollView を取得
            if let scrollview = uiView.superview?.superview?.superview as? UIScrollView,
               !context.coordinator.isDelegateAdded {
                
                // デリゲートを設定（初回のみ）
                scrollview.delegate = context.coordinator
                context.coordinator.isDelegateAdded = true
            }
        }
    }
    
    // MARK: - UIScrollViewDelegate 実装
    class Coordinator: NSObject, UIScrollViewDelegate {
        var parent: ScrollDetector
        
        init(parent: ScrollDetector) {
            self.parent = parent
        }
        
        // デリゲートが既に設定されたかどうかのフラグ（重複防止）
        var isDelegateAdded: Bool = false
        
        // スクロール中に呼び出される（常に現在のオフセットを通知）
        func scrollViewDidScroll(_ scrollView: UIScrollView) {
            parent.onScroll(scrollView.contentOffset.y)
        }
        
        // ドラッグ終了時に呼ばれる（慣性スクロール開始前）
        func scrollViewWillEndDragging(
            _ scrollView: UIScrollView,
            withVelocity velocity: CGPoint,
            targetContentOffset: UnsafeMutablePointer<CGPoint>
        ) {
            parent.onDraggingEnd(targetContentOffset.pointee.y, velocity.y)
        }

        // 慣性スクロールが完全に停止したときに呼ばれる（終了時の速度を再取得）
        func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
            let velocity = scrollView.panGestureRecognizer.velocity(in: scrollView.panGestureRecognizer.view)
            parent.onDraggingEnd(scrollView.contentOffset.y, velocity.y)
        }
    }
}
