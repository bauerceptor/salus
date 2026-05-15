document.addEventListener("DOMContentLoaded", function() {
  const iconLlama = document.querySelector("[data-icon-llama]");

  if (!iconLlama) return;

  const svg = iconLlama.querySelector("svg");
  const llama = svg.querySelector("#llama");
  let mouse = { x: 0, y: 0 };
  const width = window.innerWidth / 2;
  const height = window.innerHeight / 2;

  iconLlama.addEventListener("mousemove", function(event) {
    mouse.x = ((width - event.pageX) * -1) / width;
    mouse.y = ((height - event.pageY) * 1) / height;
    iconLlama.style.setProperty("--mouseX", mouse.x);
    iconLlama.style.setProperty("--mouseY", mouse.y);
  });

  svg.classList.add("loaded");

  setTimeout(function() {
    llama.classList.add("animate");
  }, 2150);
});
