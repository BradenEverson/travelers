var memory = new WebAssembly.Memory({
    initial: 2,
});

var x;
var y;

var importObject = {
    env: {
        updatePosition: (new_x, new_y) => {
            x = new_x;
            y = new_y;

            console.log(`New position is (${x}, ${y})`)
        }, 
        moveRelative: (dx, dy) => {
            x += dx;
            y += dy;

            console.log(`New position is (${x}, ${y})`)
        },
        memory: memory,
    },
};

WebAssembly.instantiateStreaming(fetch("wasm/traveler_wasm.wasm"), importObject).then((result) => {
    const wasmMemoryArray = new Uint8Array(memory.buffer);
    result.instance.exports.moveRoutine();
});
