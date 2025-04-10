var memory = new WebAssembly.Memory({
    initial: 2,
    maximum: 2,
});

var importObject = {
    env: {
        updatePosition: (x, y) => console.log("Moving to " + x + ", " + y), 
        memory: memory,
    },
};

WebAssembly.instantiateStreaming(fetch("wasm/traveler_wasm.wasm"), importObject).then((result) => {
    const wasmMemoryArray = new Uint8Array(memory.buffer);
    result.instance.exports.move(1, 2);
});
