const GRID_SIZE = 64;
const OPEN = 0;
const ROCK = 2;
const WOOD = 3;
const STORM = 4;
const TRAP = 5;

let tile_types = [];
let stormLevel = 0;
let canvas, ctx;

let spawnable_points = [];

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
                spawnable_points.push([x, y]);
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

function getTileColor(x, y) {
    if (inStorm(x, y)) return "#676bc2";
    switch(tile_types[y][x]) {
        case ROCK: return "#6b7280";
        case WOOD: return "#854d0e";
        case OPEN: return "#4ade80";
        case ENEMY: return "#9333ea";
        case TRAP: return "#380303";
        default: return "#000000";
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
    return x < stormLevel || x >= GRID_SIZE - stormLevel ||
        y < stormLevel || y >= GRID_SIZE - stormLevel;
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

function startGame() {
    // TODO: Request who's in the game and load em all

    setInterval(updateStorm, 30000); 
    setInterval(tick, 25);
}

function tick() {
    // TODO: WASM tick
    drawGrid();
}

function updateStorm() {
    stormLevel = Math.min(stormLevel + 1, GRID_SIZE/2);
    document.getElementById("storm").textContent = `Storm Level: ${stormLevel}`;
}

window.addEventListener("load", init);
