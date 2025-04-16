let memory = new WebAssembly.Memory({
    initial: 2,
});

const customKeywords = ["move", "left", "right", "up", "down"];

editor = CodeMirror.fromTextArea(document.getElementById('code'), {
    mode: {
        name: "javascript",
        extraKeywords: customKeywords.join(" ")
    },
    theme: "dracula",
    lineNumbers: true,
    tabSize: 2,
    indentUnit: 2,
    lineWrapping: true,
    autoCloseBrackets: true,
    extraKeys: {
        "Tab": (cm) => {
            if (cm.somethingSelected()) cm.indentSelection("add");
            else cm.execCommand("insertSoftTab");
        },
        "Ctrl-Space": "autocomplete"
    },
    gutters: ["CodeMirror-linenumbers"]
});

editor.on('inputRead', (cm, input) => {
    if (input.text && input.text[0].trim()) {
        CodeMirror.commands.autocomplete(cm, null, {
            completeSingle: false,
            hint: () => {
                const cur = cm.getCursor();
                const token = cm.getTokenAt(cur);
                const word = token.string;
                const list = [
                    ...customKeywords,
                    ...["if", "else", "let", "for", "while"]
                ].filter(kw => kw.startsWith(word))
                    .map(kw => ({text: kw}));

                return {
                    list: list,
                    from: CodeMirror.Pos(cur.line, token.start),
                    to: CodeMirror.Pos(cur.line, token.end)
                };
            }
        });
    }
});

let x = 0;
let y = 0;

var grid = {x:32, y:32}

let canvas = document.getElementById("grid");
let ctx = canvas.getContext("2d");

async function drawGrid() {
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    
    const cellWidth = canvas.width / grid.x;
    const cellHeight = canvas.height / grid.y;
    
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
            drawGrid();
        }, 
        moveRelative: (dx, dy) => {
            x += dx;
            y += dy;
            drawGrid();
        },

        log_js: (ptr, len) => {
            const buffer = new Uint8Array(memory.buffer, ptr, len);
            const str = new TextDecoder().decode(buffer);
            console.log(str);
        },

        memory: memory,
    },
};

WebAssembly.instantiateStreaming(fetch("wasm/traveler_wasm.wasm"), importObject).then((result) => {
    const wasmMemoryArray = new Uint8Array(memory.buffer);

    function stringToPtr(str) {
        const encoder = new TextEncoder();
        const encoded = encoder.encode(str);
        const ptr = result.instance.exports.alloc(encoded.length);
        const mem = new Uint8Array(memory.buffer);
        mem.set(encoded, ptr);

        return [ptr, encoded.length];
    }

    
    document.getElementById("run").addEventListener("click", () => {
        if (!result.instance) {
            console.error("WASM not loaded yet");
            return;
        }

        const code = editor.getValue();
        const [ptr, len] = stringToPtr(code);
        const res = result.instance.exports.loadProgram(ptr, len);
        console.log(res);
    });

    setInterval(() => {
        result.instance.exports.step();
    }, 50);
});
