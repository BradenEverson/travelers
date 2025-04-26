let memory = new WebAssembly.Memory({
  initial: 2,
});

const customKeywords = [
  "move",
  "left",
  "right",
  "up",
  "down",
  "if",
  "else",
  "let",
  "while",
  "for",
  "true",
  "false",
  "and",
  "or",
  "peek",
  "attack",
  "stone",
  "wood",
  "open",
  "enemy",
  "border",
  "storm",
  "trap",
];

editor = CodeMirror.fromTextArea(document.getElementById("code"), {
  mode: {
    name: "javascript",
    extraKeywords: customKeywords.join(" "),
  },
  theme: "dracula",
  lineNumbers: true,
  tabSize: 2,
  indentUnit: 2,
  lineWrapping: true,
  autoCloseBrackets: true,
  extraKeys: {
    Tab: (cm) => {
      if (cm.somethingSelected()) cm.indentSelection("add");
      else cm.execCommand("insertSoftTab");
    },
    "Ctrl-Space": "autocomplete",
  },
  gutters: ["CodeMirror-linenumbers"],
});

editor.on("inputRead", (cm, input) => {
  if (input.text && input.text[0].trim()) {
    CodeMirror.commands.autocomplete(cm, null, {
      completeSingle: false,
      hint: () => {
        const cur = cm.getCursor();
        const token = cm.getTokenAt(cur);
        const word = token.string;
        const list = customKeywords
          .filter((kw) => kw.startsWith(word))
          .map((kw) => ({ text: kw }));

        return {
          list: list,
          from: CodeMirror.Pos(cur.line, token.start),
          to: CodeMirror.Pos(cur.line, token.end),
        };
      },
    });
  }
});

let x = Math.floor(Math.random() * 32);
let y = Math.floor(Math.random() * 32);
let dead = false;

let stormLevel = 0;
let stormTicks = 0;

function resetStorm() {
  stormLevel = 0;
  stormTicks = 0;
}

// Tile Types
const OPEN = 0;
const ENEMY = 1;
const ROCK = 2;
const WOOD = 3;
const STORM = 4;
const TRAP = 5;

let health = 100;
let selectedType = OPEN;

function create2DArray(rows, cols) {
  const arr = new Array(rows);
  for (let i = 0; i < rows; i++) {
    arr[i] = new Array(cols).fill(OPEN);
  }
  return arr;
}

var grid = { x: 32, y: 32 };
var tile_types = create2DArray(grid.y, grid.x);

let canvas = document.getElementById("grid");
let ctx = canvas.getContext("2d");

function inStorm(lx, ly) {
  return (
    lx < stormLevel ||
    lx >= grid.x - stormLevel ||
    ly < stormLevel ||
    ly >= grid.y - stormLevel
  );
}

async function drawGrid() {
  ctx.clearRect(0, 0, canvas.width, canvas.height);

  const cellWidth = canvas.width / grid.x;
  const cellHeight = canvas.height / grid.y;

  for (let ly = 0; ly < grid.y; ly++) {
    for (let lx = 0; lx < grid.x; lx++) {
      if (x == lx && y == ly) {
        continue;
      }
      const type = tile_types[ly][lx];
      let color;
      if (inStorm(lx, ly)) {
        color = "#676bc2";
      } else {
        switch (type) {
          case OPEN:
            color = "#4ade80";
            break;
          case ENEMY:
            color = "#9333ea";
            break;
          case ROCK:
            color = "#6b7280";
            break;
          case WOOD:
            color = "#854d0e";
            break;
          case TRAP:
            color = "#380303";
            break;
          default:
            color = "#000000";
        }
      }
      ctx.fillStyle = color;
      ctx.fillRect(lx * cellWidth, ly * cellHeight, cellWidth, cellHeight);
    }
  }

  ctx.strokeStyle = "#000000";
  ctx.lineWidth = 1;
  ctx.beginPath();

  for (let i = 0; i <= grid.x; i++) {
    const lineX = i * cellWidth;
    ctx.moveTo(lineX, 0);
    ctx.lineTo(lineX, canvas.height);
  }

  for (let i = 0; i <= grid.y; i++) {
    const lineY = i * cellHeight;
    ctx.moveTo(0, lineY);
    ctx.lineTo(canvas.width, lineY);
  }
  ctx.stroke();

  if (x >= 0 && x < grid.x && y >= 0 && y < grid.y) {
    const highlightX = x * cellWidth;
    const highlightY = y * cellHeight;

    ctx.fillStyle = "rgba(255, 0, 0, 0.5)";
    ctx.fillRect(highlightX, highlightY, cellWidth, cellHeight);

    ctx.strokeStyle = "#000000";
    ctx.strokeRect(highlightX, highlightY, cellWidth, cellHeight);
  }
}

document.querySelectorAll(".tile-btn").forEach((button) => {
  button.addEventListener("click", function () {
    document
      .querySelectorAll(".tile-btn")
      .forEach((btn) => btn.classList.remove("active"));
    this.classList.add("active");
    selectedType = parseInt(this.dataset.type);
  });
});

canvas.addEventListener("click", (event) => {
  const rect = canvas.getBoundingClientRect();
  const scaleX = canvas.width / rect.width;
  const scaleY = canvas.height / rect.height;

  const mouseX = (event.clientX - rect.left) * scaleX;
  const mouseY = (event.clientY - rect.top) * scaleY;

  const cellWidth = canvas.width / grid.x;
  const cellHeight = canvas.height / grid.y;

  const x = Math.floor(mouseX / cellWidth);
  const y = Math.floor(mouseY / cellHeight);

  if (x >= 0 && x < grid.x && y >= 0 && y < grid.y) {
    tile_types[y][x] = selectedType;
    drawGrid();
  }
});

function handleResize() {
  canvas.width = canvas.clientWidth;
  canvas.height = canvas.clientHeight;
  drawGrid();
}

handleResize();
window.addEventListener("resize", handleResize);

let importObject = {
  env: {
    updatePosition: (new_x, new_y) => {
      x = new_x;
      y = new_y;
    },
    moveRelative: (dx, dy) => {
      if (
        (x == 0 && dx < 0) ||
        (y == 0 && dy < 0) ||
        (x == grid.x - 1 && dx > 0) ||
        (y == grid.y - 1 && dy > 0)
      ) {
        return -1;
      }

      const nx = x + dx;
      const ny = y + dy;

      if (tile_types[ny][nx] != OPEN && tile_types[ny][nx] != TRAP) {
        return -1;
      }

      x = nx;
      y = ny;

      if (tile_types[ny][nx] == TRAP) {
          tile_types[ny][nx] = OPEN
          return -2;
      }

      return 0;
    },

    updateHealthBar: (hp) => {
      document.getElementById("hp").innerText = `Health: ${hp}/100`;
    },

    attackAt: (dx, dy) => {
      const nx = x + dx;
      const ny = y + dy;

      if (tile_types[ny][nx] == WOOD) {
        tile_types[ny][nx] = OPEN;
        return WOOD;
      } else if (tile_types[ny][nx] == ENEMY) {
        tile_types[ny][nx] = OPEN;
        return ENEMY;
      }

      return 0.0;
    },

    trapAt: (dx, dy) => {
      const nx = x + dx;
      const ny = y + dy;

      if ((nx < 0 || nx >= grid.x || ny < 0 || ny >= grid.y) || tile_types[ny][nx] != OPEN) {
        return false;
      }
      
      tile_types[ny][nx] = TRAP;

      return true;
    },

    lookAtRelative: (dx, dy) => {
      const nx = x + dx;
      const ny = y + dy;

      if (nx < 0 || nx >= grid.x || ny < 0 || ny >= grid.y) {
        return -1;
      } else if (inStorm(nx, ny)) { 
        return STORM;
      }else {
        return tile_types[y + dy][x + dx];
      }
    },

    log_js: (ptr, len) => {
      const buffer = new Uint8Array(memory.buffer, ptr, len);
      const str = new TextDecoder().decode(buffer);
      console.log(str);
    },

    memory: memory,
  },
};

WebAssembly.instantiateStreaming(
  fetch("wasm/traveler_wasm.wasm"),
  importObject,
).then((result) => {
  const wasmMemoryArray = new Uint8Array(memory.buffer);

  function stringToPtr(str) {
    const encoder = new TextEncoder();
    const encoded = encoder.encode(str);
    const ptr = result.instance.exports.alloc(encoded.length);
    const mem = new Uint8Array(memory.buffer);
    mem.set(encoded, ptr);

    return [ptr, encoded.length];
  }

  function tickStorm() {
    stormTicks += 1;

    if (stormTicks % 80 == 0 && inStorm(x, y)) {
      result.instance.exports.doDamage(1);
    }

    if (stormTicks % 2000 == 0) {
      stormLevel += 1;
    }
  }

  document.getElementById("run").addEventListener("click", () => {
    if (!result.instance) {
      console.error("WASM not loaded yet");
      return;
    }

    const code = editor.getValue();
    const [ptr, len] = stringToPtr(code);
    const res = result.instance.exports.loadProgram(ptr, len);

    resetStorm();

    setInterval(() => {
      tickStorm();
      drawGrid();
      result.instance.exports.step();

      if (result.instance.exports.getHealth() == 0 && !dead) {
        dead = true;
        alert("You're so dead bro")
      }
    }, 25);
  });
});

