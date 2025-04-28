const GRID_SIZE = 64;

const OPEN = 0;
const ROCK = 2;
const WOOD = 3;
const STORM = 4;
const TRAP = 5;

const UP = 0;
const RIGHT = 1;
const DOWN = 2;
const LEFT = 3;

let tile_types = [];
let stormLevel = 0;
let canvas, ctx;

let spawnablePoints = [];

let x = 0;
let y = 0;

let enemies = [];

function init() {
  canvas = document.getElementById("grid");
  ctx = canvas.getContext("2d");
  generateTerrain();
  startCountdown();
}

function generateTerrain() {
  let x = 0;
  tile_types = Array.from({ length: GRID_SIZE }, () => {
    let y = 0;
    const row = Array.from({ length: GRID_SIZE }, () => {
      const rand = Math.random();
      let tile;
      if (rand < 0.1) {
        tile = ROCK;
      } else if (rand < 0.2) {
        tile = WOOD;
      } else {
        tile = OPEN;
        spawnablePoints.push([x, y]);
      }
      y += 1;
      return tile;
    });
    x += 1;
    return row;
  });
}

function drawGrid() {
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  const cellSize = canvas.width / GRID_SIZE;

  for (let y = 0; y < GRID_SIZE; y++) {
    for (let x = 0; x < GRID_SIZE; x++) {
      ctx.fillStyle = getTileColor(x, y);
      ctx.fillRect(x * cellSize, y * cellSize, cellSize, cellSize);
    }
  }

  drawGridLines(cellSize);
}

function getTileColor(lx, ly) {
  if (inStorm(lx, ly)) return "#676bc2";
  if (x == lx && y == ly) return "#fc0303";

  switch (tile_types[ly][lx]) {
    case ROCK:
      return "#6b7280";
    case WOOD:
      return "#854d0e";
    case OPEN:
      return "#4ade80";
    case ENEMY:
      return "#9900ff";
    case TRAP:
      return "#380303";
    default:
      return "#000000";
  }
}

function drawGridLines(cellSize) {
  ctx.strokeStyle = "#1a202c";
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

function inStorm(x, y) {
  return (
    x < stormLevel ||
    x >= GRID_SIZE - stormLevel ||
    y < stormLevel ||
    y >= GRID_SIZE - stormLevel
  );
}

async function startCountdown() {
  const countdownElement = document.getElementById("countdown");
  countdownElement.style.display = "block";

  for (let i = 3; i > 0; i--) {
    countdownElement.textContent = i;
    await new Promise((resolve) => setTimeout(resolve, 1000));
  }
  countdownElement.textContent = "FIGHT!";
  await new Promise((resolve) => setTimeout(resolve, 500));
  countdownElement.style.display = "none";
  startGame();
}

function shuffleArray(array) {
  for (let i = array.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [array[i], array[j]] = [array[j], array[i]];
  }
  return array;
}

function startGame() {
  const id = localStorage.getItem("id");
  fetch("/create?" + new URLSearchParams({
    id: id,
}), {
    method: "GET",
  })
    .then((response) => {
      if (!response.ok) {
        throw new Error("Network response was not ok");
      }
      return response.json();
    })
    .then((json) => {
        const spawns = shuffleArray(spawnablePoints)
        playerSpawn = spawns[0];


        x = playerSpawn[0];
        y = playerSpawn[1];
        console.log(`${x}, ${y}`);
    })
    .catch((error) => console.error("Error: ", error));

  setInterval(updateStorm, 30000);
  setInterval(tick, 25);
}

function tick() {
  // TODO: WASM tick
  drawGrid();
}

function updateStorm() {
  stormLevel = Math.min(stormLevel + 1, GRID_SIZE / 2);
  document.getElementById("storm").textContent = `Storm Level: ${stormLevel}`;
}

window.addEventListener("load", init);
