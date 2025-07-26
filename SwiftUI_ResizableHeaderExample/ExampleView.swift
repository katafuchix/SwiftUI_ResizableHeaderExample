//
//  ExampleView.swift
//  SwiftUI_ResizableHeaderExample
//
//  Created by cano on 2025/07/26.
//

import SwiftUI

struct ExampleView: View {
    var size: CGSize            // 画面サイズ
    var safeArea: EdgeInsets    // セーフエリア情報

    /// スクロールオフセット（マイナス方向に伸びる）
    @State private var offsetY: CGFloat = 0

    var body: some View {
        ScrollViewReader { scrollProxy in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    // ヘッダー（プロフィール）
                    HeaderView()
                        .zIndex(1000) // 上に表示

                    // ダミーカード
                    SampleCardsView()
                }
                .id("SCROLLVIEW") // スクロール先指定用 ID
                .background {
                    // スクロール位置検出ビュー
                    ScrollDetector { offset in
                        // オフセットを保存（符号反転してヘッダー用に使う）
                        offsetY = -offset
                    } onDraggingEnd: { offset, velocity in
                        // ヘッダー途中までスクロールされた場合は自動で戻す
                        let headerHeight = (size.height * 0.3) + safeArea.top
                        let minimumHeaderHeight = 65 + safeArea.top
                        
                        // スクロール後の想定終了位置を推定
                        let targetEnd = offset + (velocity * 45)

                        if targetEnd < (headerHeight - minimumHeaderHeight) && targetEnd > 0 {
                            withAnimation(.interactiveSpring(response: 0.55, dampingFraction: 0.65, blendDuration: 0.65)) {
                                scrollProxy.scrollTo("SCROLLVIEW", anchor: .top)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - ヘッダービュー
    @ViewBuilder
    func HeaderView() -> some View {
        let headerHeight = (size.height * 0.3) + safeArea.top
        let minimumHeaderHeight = 65 + safeArea.top

        // スクロールオフセットに応じた 0〜1 の進捗値
        let progress = max(min(-offsetY / (headerHeight - minimumHeaderHeight), 1), 0)

        GeometryReader { _ in
            ZStack {
                // 背景グラデーション
                Rectangle()
                    .fill(Color("Gray").gradient)

                VStack(spacing: 15) {
                    // プロフィール画像
                    GeometryReader {
                        let rect = $0.frame(in: .global)

                        let halfScaledHeight = (rect.height * 0.3) * 0.5
                        let midY = rect.midY
                        let bottomPadding: CGFloat = 15

                        // スクロール時のYずれを計算
                        let resizedOffsetY = (midY - (minimumHeaderHeight - halfScaledHeight - bottomPadding))

                        Image("Pic")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: rect.width, height: rect.height)
                            .clipShape(Circle())
                            // 拡大縮小（最大 0.7 縮小）
                            .scaleEffect(1 - (progress * 0.7), anchor: .leading)
                            // スクロール時に位置調整（左寄せ＆上へ）
                            .offset(x: -(rect.minX - 15) * progress, y: -resizedOffsetY * progress)
                    }
                    .frame(width: headerHeight * 0.5, height: headerHeight * 0.5)

                    // ユーザー名
                    Text("iJustine")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        // テキストも画像と同様に移動・縮小
                        .moveText(progress, headerHeight, minimumHeaderHeight)
                }
                .padding(.top, safeArea.top)
                .padding(.bottom, 15)
            }
            // ヘッダーの高さ調整（最小値以下にならない）
            .frame(height: max(headerHeight + offsetY, minimumHeaderHeight), alignment: .bottom)
            .offset(y: -offsetY) // スクロール位置に合わせてヘッダーを押し上げ
        }
        .frame(height: headerHeight)
    }

    // MARK: - カードリスト表示
    @ViewBuilder
    func SampleCardsView() -> some View {
        VStack(spacing: 15) {
            ForEach(1...25, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(.black.opacity(0.05))
                    .frame(height: 75)
            }
        }
        .padding(15)
    }
}

// MARK: - テキスト移動用 View 拡張
fileprivate extension View {
    /// スクロール進捗に応じてテキストの縮小・移動を適用
    func moveText(_ progress: CGFloat, _ headerHeight: CGFloat, _ minimumHeaderHeight: CGFloat) -> some View {
        self
            .hidden() // テキスト自体は非表示（GeometryReaderで位置取得用）
            .overlay {
                GeometryReader { proxy in
                    let rect = proxy.frame(in: .global)
                    let midY = rect.midY

                    // テキスト縮小率 (最大15%)
                    let halfScaledTextHeight = (rect.height * 0.85) / 2

                    let profileImageHeight = (headerHeight * 0.5)
                    let scaledImageHeight = profileImageHeight * 0.3
                    let halfScaledImageHeight = scaledImageHeight / 2

                    // VStackのspacingを考慮して調整
                    let vStackSpacing: CGFloat = 4.5

                    // 移動量計算（画像に合わせて自然に追従）
                    let resizedOffsetY = midY - (minimumHeaderHeight - halfScaledTextHeight - vStackSpacing - halfScaledImageHeight)

                    self
                        .scaleEffect(1 - (progress * 0.15)) // 縮小
                        .offset(y: -resizedOffsetY * progress) // 移動
                }
            }
    }
}



struct ExampleView_Previews: PreviewProvider {
    static var previews: some View {
            GeometryReader {
                let size = $0.size
                let safeArea = $0.safeAreaInsets
                
                ExampleView(size: size, safeArea: safeArea)
                    .ignoresSafeArea(.all, edges: .top)
            }
        
    }
}
