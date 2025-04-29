const GRID_SIZE = 64;
const STORM_DAMAGE_INTERVAL = 20;
const GAME_TICK_INTERVAL = 25;
const STORM_GROW_INTERVAL = 30000;

const TILE_TYPES = {
  OPEN: 0,
  ENEMY: 1,
  ROCK: 2,
  WOOD: 3,
  STORM: 4,
  TRAP: 5
};

const DIRECTIONS = {
  UP: 0,
  RIGHT: 1,
  DOWN: 2,
  LEFT: 3
};

const COLORS = {
  PLAYER: "#fc0303",
  ENEMY: "#9900ff",
  STORM: "#676bc2",
  ROCK: "#6b7280",
  WOOD: "#854d0e",
  GRASS: "#4ade80",
  TRAP: "#380303",
  GRID_LINES: "#1a202c"
};

let gameState = {
  tileMap: [],
  stormLevel: 0,
  player: { x: 0, y: 0, instance: null, dead: false },
  enemies: [],
  spawnPoints: []
};

let canvas, ctx;
let memory = new WebAssembly.Memory({ initial: 2 });

function init() {
  canvas = document.getElementById("grid");
  ctx = canvas.getContext("2d");
  generateTerrain();
  startCountdown();
}

function generateTerrain() {
  gameState.tileMap = Array.from({ length: GRID_SIZE }, (_, y) => 
    Array.from({ length: GRID_SIZE }, (_, x) => {
      const rand = Math.random();
      let tileType;

      if (rand < 0.1) tileType = TILE_TYPES.ROCK;
      else if (rand < 0.2) tileType = TILE_TYPES.WOOD;
      else {
        tileType = TILE_TYPES.OPEN;
        gameState.spawnPoints.push([x, y]);
      }

      return tileType;
    })
  );
}

function drawGrid() {
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  const cellSize = canvas.width / GRID_SIZE;

  gameState.tileMap.forEach((row, y) => {
    row.forEach((tile, x) => {
      ctx.fillStyle = getTileColor(x, y);
      ctx.fillRect(x * cellSize, y * cellSize, cellSize, cellSize);
    });
  });

  drawGridLines(cellSize);
}

function getTileColor(x, y) {
  if (x === gameState.player.x && y === gameState.player.y) return COLORS.PLAYER;
  if (gameState.tileMap[y][x] === TILE_TYPES.ENEMY) return COLORS.ENEMY;
  if (inStormArea(x, y)) return COLORS.STORM;

  switch (gameState.tileMap[y][x]) {
    case TILE_TYPES.ROCK: return COLORS.ROCK;
    case TILE_TYPES.WOOD: return COLORS.WOOD;
    case TILE_TYPES.TRAP: return COLORS.TRAP;
    default: return COLORS.GRASS;
  }
}

function drawGridLines(cellSize) {
  ctx.strokeStyle = COLORS.GRID_LINES;
  ctx.lineWidth = 1;

  for (let i = 0; i <= GRID_SIZE; i++) {
    ctx.beginPath();
    ctx.moveTo(i * cellSize, 0);
    ctx.lineTo(i * cellSize, canvas.height);
    ctx.stroke();
    
    ctx.beginPath();
    ctx.moveTo(0, i * cellSize);
    ctx.lineTo(canvas.width, i * cellSize);
    ctx.stroke();
  }
}

function inStormArea(x, y) {
  return x < gameState.stormLevel ||
         x >= GRID_SIZE - gameState.stormLevel ||
         y < gameState.stormLevel ||
         y >= GRID_SIZE - gameState.stormLevel;
}

async function startCountdown() {
  const countdownElement = document.getElementById("countdown");
  countdownElement.style.display = "block";

  for (let i = 3; i > 0; i--) {
    countdownElement.textContent = i;
    await new Promise(resolve => setTimeout(resolve, 1000));
  }
  
  countdownElement.textContent = "FIGHT!";
  await new Promise(resolve => setTimeout(resolve, 500));
  countdownElement.style.display = "none";
  startGame();
}

async function startGame() {
  try {
    const response = await fetch(`/create?id=${localStorage.getItem("id")}`);
    if (!response.ok) throw new Error("Network error");
    const gameData = await response.json();

    initializePlayer(gameData);
    initializeEnemies(gameData);
    setupGameLoop();
  } catch (error) {
    console.error("Game initialization failed:", error);
  }
}

function initializePlayer(gameData) {
  const spawnPoint = shuffleArray(gameState.spawnPoints)[0];
  [gameState.player.x, gameState.player.y] = spawnPoint;

  const playerVtable = createPlayerVtable();
  loadWasmInstance(
    gameData.creator,
    memory,
    playerVtable,
    () => inStormArea(gameState.player.x, gameState.player.y),
    () => gameState.player.dead = true
  );
}

function initializeEnemies(gameData) {
  gameData.others.forEach((enemyCode, index) => {
    const spawnPoint = gameState.spawnPoints[index + 1];
    const enemy = {
      x: spawnPoint[0],
      y: spawnPoint[1],
      instance: null,
      dead: false,
      memory: new WebAssembly.Memory({ initial: 2 })
    };

    const enemyVtable = createEnemyVtable(enemy, index);
    loadWasmInstance(
      enemyCode,
      enemy.memory,
      enemyVtable,
      () => inStormArea(enemy.x, enemy.y),
      () => handleEnemyDeath(enemy)
    );

    gameState.enemies.push(enemy);
    gameState.tileMap[enemy.y][enemy.x] = TILE_TYPES.ENEMY;
  });
}

function createPlayerVtable() {
  return {
    env: {
      moveRelative: (dx, dy) => handlePlayerMovement(dx, dy),
      updateHealthBar: updatePlayerHealth,
      attackAt: (dx, dy) => handlePlayerAttack(dx, dy),
      trapAt: (dx, dy) => handlePlayerTrap(dx, dy),
      lookAtRelative: (dx, dy) => lookAtPosition(gameState.player.x + dx, gameState.player.y + dy),
      log_js: logMessage,
      memory: memory
    }
  };
}

function createEnemyVtable(enemy, index) {
  return {
    env: {
      moveRelative: (dx, dy) => handleEnemyMovement(enemy, dx, dy),
      updateHealthBar: () => {},
      attackAt: () => 0,
      trapAt: () => false,
      lookAtRelative: (dx, dy) => lookAtPosition(enemy.x + dx, enemy.y + dy),
      log_js: logMessage,
      memory: enemy.memory
    }
  };
}

function loadWasmInstance(code, memory, vtable, damageCheck, deathHandler) {
  WebAssembly.instantiateStreaming(
    fetch("wasm/traveler_wasm.wasm"),
    { env: vtable.env }
  ).then(({ instance }) => {
    loadWasmProgram(code, memory, instance);
    setupWasmLoop(instance, damageCheck, deathHandler);
  });
}

function loadWasmProgram(code, memory, instance) {
  const encoder = new TextEncoder();
  const encodedCode = encoder.encode(code);
  const ptr = instance.exports.alloc(encodedCode.length);
  new Uint8Array(memory.buffer).set(encodedCode, ptr);
  instance.exports.loadProgram(ptr, encodedCode.length);
}

function setupWasmLoop(instance, damageCheck, deathHandler) {
  let stormTicks = 0;
  const intervalId = setInterval(() => {
    if (instance.exports.getHealth() === 0) return;
    
    stormTicks++;
    instance.exports.step();

    if (stormTicks % STORM_DAMAGE_INTERVAL === 0 && damageCheck()) {
      instance.exports.doDamage(1);
    }

    if (instance.exports.getHealth() === 0) {
      clearInterval(intervalId);
      deathHandler();
    }
  }, GAME_TICK_INTERVAL);
}

function handlePlayerMovement(dx, dy) {
  const newX = gameState.player.x + dx;
  const newY = gameState.player.y + dy;

  if (!isValidPosition(newX, newY)) return -1;
  
  const targetTile = gameState.tileMap[newY][newX];
  if (![TILE_TYPES.OPEN, TILE_TYPES.TRAP].includes(targetTile)) return -1;

  gameState.player.x = newX;
  gameState.player.y = newY;

  if (targetTile === TILE_TYPES.TRAP) {
    gameState.tileMap[newY][newX] = TILE_TYPES.OPEN;
    return -2;
  }

  return 0;
}

function handleEnemyMovement(enemy, dx, dy) {
  const newX = enemy.x + dx;
  const newY = enemy.y + dy;

  if (!isValidPosition(newX, newY)) return -1;
  
  const targetTile = gameState.tileMap[newY][newX];
  if (![TILE_TYPES.OPEN, TILE_TYPES.TRAP].includes(targetTile)) return -1;

  gameState.tileMap[enemy.y][enemy.x] = TILE_TYPES.OPEN;
  enemy.x = newX;
  enemy.y = newY;
  gameState.tileMap[newY][newX] = TILE_TYPES.ENEMY;

  if (targetTile === TILE_TYPES.TRAP) {
    gameState.tileMap[newY][newX] = TILE_TYPES.OPEN;
    return -2;
  }

  return 0;
}

function handlePlayerAttack(dx, dy) {
  const targetX = gameState.player.x + dx;
  const targetY = gameState.player.y + dy;
  
  if (!isValidPosition(targetX, targetY)) return 0;
  
  const tile = gameState.tileMap[targetY][targetX];
  if (tile === TILE_TYPES.WOOD || tile === TILE_TYPES.ENEMY) {
    gameState.tileMap[targetY][targetX] = TILE_TYPES.OPEN;
    return tile === TILE_TYPES.ENEMY ? 1 : 2;
  }
  return 0;
}

function handlePlayerTrap(dx, dy) {
  const targetX = gameState.player.x + dx;
  const targetY = gameState.player.y + dy;
  
  if (!isValidPosition(targetX, targetY)) return false;
  if (gameState.tileMap[targetY][targetX] !== TILE_TYPES.OPEN) return false;
  
  gameState.tileMap[targetY][targetX] = TILE_TYPES.TRAP;
  return true;
}

function lookAtPosition(x, y) {
  if (!isValidPosition(x, y)) return -1;
  if (inStormArea(x, y)) return TILE_TYPES.STORM;
  return gameState.tileMap[y][x];
}

function updatePlayerHealth(hp) {
  document.getElementById("hp").textContent = `Health: ${hp}/100`;
}

function handleEnemyDeath(enemy) {
  gameState.tileMap[enemy.y][enemy.x] = TILE_TYPES.OPEN;
  enemy.dead = true;
  console.log("Enemy defeated!");
}

function isValidPosition(x, y) {
  return x >= 0 && x < GRID_SIZE && y >= 0 && y < GRID_SIZE;
}

function logMessage(ptr, len) {
  const buffer = new Uint8Array(memory.buffer, ptr, len);
  console.log(new TextDecoder().decode(buffer));
}

function shuffleArray(array) {
  for (let i = array.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [array[i], array[j]] = [array[j], array[i]];
  }
  return array;
}

function setupGameLoop() {
  setInterval(() => {
    gameState.stormLevel = Math.min(gameState.stormLevel + 1, GRID_SIZE / 2);
    document.getElementById("storm").textContent = `Storm Level: ${gameState.stormLevel}`;
  }, STORM_GROW_INTERVAL);

  setInterval(() => {
    drawGrid();
    checkGameOver();
  }, GAME_TICK_INTERVAL);
}

function checkGameOver() {
  if (gameState.player.dead) {
    alert("Game Over - You died!");
    location.reload();
  }
  
  const aliveEnemies = gameState.enemies.filter(e => !e.dead);
  if (aliveEnemies.length === 0) {
    alert("Victory! All enemies defeated!");
    location.reload();
  }
}

window.addEventListener("load", init);
