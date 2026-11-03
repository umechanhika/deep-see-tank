import { Game } from './Game';

const container = document.getElementById('app');
if (!container) {
  throw new Error('#app container not found');
}

const game = new Game(container);
game.start();

// ホットリロード時にループを破棄してリーク・二重描画を防ぐ
if (import.meta.hot) {
  import.meta.hot.dispose(() => game.dispose());
}
