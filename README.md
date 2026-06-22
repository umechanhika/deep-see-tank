# deep-see-tank — 深海水槽放置ゲーム

Three.js を使ったブラウザ動作の箱庭系放置ゲーム。
暗い深海水槽を眺めるだけで生態系が育っていく、癒し系のインタラクティブ体験。

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

```bash
npm install
npm run dev      # 開発サーバ起動
npm run build    # 型チェック + 本番ビルド
npm run preview  # ビルド結果のプレビュー
```

## 遊び方

- **ドラッグ**: 視点を回す（OrbitControls）。操作しなければ自動でゆっくり回転。
- **クリック**: その地点に餌をまく。魚が集まり、珊瑚が少し成長する。
- **ホバー**: 生き物にカーソルを合わせると名前とレベルを表示。

時間経過（累計プレイ時間）でフェーズが進み、生き物が増えていく。
オフライン中の経過も最大24時間まで反映される。

## フェーズ進行

| フェーズ | 到達時間 | 内容 |
|---|---|---|
| 1 | 開始直後 | プランクトン |
| 2 | 5分後 | 発光クラゲ出現（最大5体） |
| 3 | 15分後 | 魚の群れ（Boid・最大30匹） |
| 4 | 30分後 | 深海魚（チョウチンアンコウ） |
| 5 | 60分後 | 完成形 |

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
