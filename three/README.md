# deep-see-tank / three.js 版

[Three.js](https://threejs.org/) で描く、深海水槽放置ゲームのブラウザ版。
遊び方とフェーズ進行はリポジトリ直下の [README](../README.md) を参照。

## 技術スタック

| 役割 | 技術 |
|---|---|
| 3Dレンダリング | Three.js (r168) |
| ビルドツール | Vite |
| 言語 | TypeScript |
| 状態管理 | 自前の `GameState` クラス |
| 永続化 | localStorage |
| ノイズ | simplex-noise |

## セットアップ

このディレクトリ（`three/`）で実行する。

```bash
npm install
npm run dev      # 開発サーバ起動
npm run build    # 型チェック + 本番ビルド（dist/ に出力）
npm run preview  # ビルド結果のプレビュー
```

## ディレクトリ構成

```
src/
├── main.ts                  # エントリーポイント
├── Game.ts                  # 全体のオーケストレーター
├── core/
│   ├── Renderer.ts          # Three.js セットアップ
│   ├── GameState.ts         # 状態管理・セーブ/ロード
│   ├── TimeManager.ts       # 放置時間の計算
│   ├── constants.ts         # 水槽寸法・フェーズしきい値
│   ├── noise.ts             # 共有シンプレックスノイズ
│   └── textures.ts          # 発光スプライト生成
├── scene/
│   ├── Tank.ts              # ガラス筐体
│   ├── Water.ts             # 水中シェーダー
│   └── Lighting.ts          # ライティング
├── creatures/
│   ├── Plankton.ts          # パーティクル
│   ├── Jellyfish.ts         # 発光クラゲ
│   ├── Fish.ts              # 魚の群れ（Boid・InstancedMesh）
│   ├── DeepSeaFish.ts       # 深海魚
│   └── CreatureManager.ts   # 出現・管理
├── environment/
│   ├── Coral.ts             # 珊瑚（L-system）
│   ├── CoralGarden.ts       # 複数珊瑚の管理
│   ├── Bubbles.ts           # 泡
│   └── SeaFloor.ts          # 砂地・岩
├── ui/
│   ├── HUD.ts               # フェーズ・時間表示
│   ├── Tooltip.ts           # 生き物の名前表示
│   ├── FeedEffect.ts        # 餌やりエフェクト
│   ├── PhaseTransition.ts   # フェーズ移行演出
│   └── AmbientAudio.ts      # 環境音
└── shaders/
    ├── water.vert.glsl / water.frag.glsl
    └── jellyfish.vert.glsl / jellyfish.frag.glsl
```
