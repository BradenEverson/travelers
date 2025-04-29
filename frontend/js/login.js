window.addEventListener("load", () => {
  const id = localStorage.getItem("id");

  if (id == null) {
    const enterBtn = document.getElementById("battle");
    enterBtn.className =
      "menu-btn disabled-btn bg-gray-700 text-gray-400 py-4 px-8 text-center rounded-lg pixel-corners text-lg font-bold";
    enterBtn.innerText = "TRAIN BEFORE FIGHTING";
  }
});
