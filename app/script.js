// Exploding smiley: click -> pop, burst of mini smileys, then bounce back.
(function () {
  const smiley = document.getElementById("smiley");
  const stage = document.getElementById("smiley-stage");
  const faces = ["😀", "😃", "😄", "😁", "😆", "😊", "🙂", "😍", "🤩", "😎"];
  const COUNT = 14;
  let busy = false;

  function burst() {
    for (let i = 0; i < COUNT; i++) {
      const el = document.createElement("span");
      el.className = "mini-smiley";
      el.textContent = faces[Math.floor(Math.random() * faces.length)];
      // spread evenly around a circle, with a little randomness
      const angle = (i / COUNT) * 2 * Math.PI + (Math.random() - 0.5) * 0.4;
      const dist = 110 + Math.random() * 80;
      el.style.setProperty("--dx", Math.cos(angle) * dist + "px");
      el.style.setProperty("--dy", Math.sin(angle) * dist + "px");
      el.style.setProperty("--r", (Math.random() * 720 - 360) + "deg");
      el.style.setProperty("--s", (0.8 + Math.random() * 0.7).toFixed(2));
      el.style.animationDelay = Math.random() * 0.08 + "s";
      el.addEventListener("animationend", () => el.remove());
      stage.appendChild(el);
    }
  }

  smiley.addEventListener("click", () => {
    if (busy) return;
    busy = true;
    smiley.classList.remove("back");
    smiley.classList.add("pop");
    setTimeout(burst, 100);                 // burst as it reaches full size
    setTimeout(() => {                       // come back
      smiley.classList.remove("pop");
      smiley.classList.add("back");
    }, 900);
    setTimeout(() => {
      smiley.classList.remove("back");
      busy = false;
    }, 1450);
  });
})();
