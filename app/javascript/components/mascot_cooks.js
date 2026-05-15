var mascotCooksTL;
var mascotCooksDimple = document.getElementById('mascot-cooks-dimple');
var mascotCooksDough2 = "M316.8,196c-30.9-45.4-64-45.4-99.5,0";
var mascotCooksDough3 = "M333.8,68.6c-43.3-7-86.7-7-130,0";
var mascotCooksSmile = document.getElementById('mascot-cooks-smile');
var mascotCooksDough = document.getElementById('mascot-cooks-dough');
var mascotCooksHandL = document.getElementById('mascot-cooks-hand-l');
var mascotCooksArmL = document.getElementById('mascot-cooks-arm-l');
var mascotCooksSleeveL = document.getElementById('mascot-cooks-sleeve-l');
var mascotCooksArmL2 = "M116.4,254.2c70.9,39.1,118.3,39.8,142.2-43.1";
var mascotCooksArmL3 = "M116.4,254.2c79.5,24.9,113,22.1,142.2-71.1";
var mascotCooksArmL4 = "M116.4,254.2c70.9,39.1,113,71.1,142.2-22.1";
var mascotCooksHandR = document.getElementById('mascot-cooks-hand-r');
var mascotCooksSleeveR = document.getElementById('mascot-cooks-sleeve-r');
var mascotCooksArmR = document.getElementById('mascot-cooks-arm-r');
var mascotCooksArmR2 = "M181.1,247.2c26,21.1,71.2,55.8,96.5-36.2";
var mascotCooksArmR3 = "M181.1,247.2c40.7,14.1,76.4,25.9,97.5-65.2";
var mascotCooksArmR4 = "M181.1,247.2c26,21.1,72.5,87,96.5-15.2";
var mascotCooksEyeL = document.getElementById('mascot-cooks-eye-l');
var mascotCooksEyeR = document.getElementById('mascot-cooks-eye-r');
var mascotCooksBounceDur = 0.2;

function initMascotCooksAnimation() {
  mascotCooksTL = new TimelineMax({ paused: true, repeat: -1, repeatDelay: 2 });
  mascotCooksTL
    .to(mascotCooksDough, mascotCooksBounceDur + 0.2, { y: 0, morphSVG: mascotCooksDough2, ease: Quad.easeOut }, "0")
    .to(mascotCooksDough, mascotCooksBounceDur + 0.2, { y: 0, morphSVG: mascotCooksDough, ease: Quad.easeIn }, mascotCooksBounceDur + 0.2)

    .to(mascotCooksHandL, mascotCooksBounceDur, { y: -15, ease: Quad.easeOut }, "0")
    .to(mascotCooksSleeveL, mascotCooksBounceDur, { morphSVG: mascotCooksArmL2, ease: Quad.easeOut }, "0")
    .to(mascotCooksArmL, mascotCooksBounceDur, { morphSVG: mascotCooksArmL2, ease: Quad.easeOut }, "0")
    .to(mascotCooksHandL, mascotCooksBounceDur, { y: 0, ease: Quad.easeIn }, mascotCooksBounceDur + 0.4)
    .to(mascotCooksSleeveL, mascotCooksBounceDur, { morphSVG: mascotCooksSleeveL, ease: Quad.easeIn }, mascotCooksBounceDur + 0.4)
    .to(mascotCooksArmL, mascotCooksBounceDur, { morphSVG: mascotCooksArmL, ease: Quad.easeIn }, mascotCooksBounceDur + 0.4)
    .to(mascotCooksHandR, mascotCooksBounceDur, { y: -15, ease: Quad.easeOut }, "0")
    .to(mascotCooksSleeveR, mascotCooksBounceDur, { morphSVG: mascotCooksArmR2, ease: Quad.easeOut }, "0")
    .to(mascotCooksArmR, mascotCooksBounceDur, { morphSVG: mascotCooksArmR2, ease: Quad.easeOut }, "0")
    .to(mascotCooksHandR, mascotCooksBounceDur, { y: 0, ease: Quad.easeIn }, mascotCooksBounceDur + 0.4)
    .to(mascotCooksSleeveR, mascotCooksBounceDur, { morphSVG: mascotCooksSleeveR, ease: Quad.easeIn }, mascotCooksBounceDur + 0.4)
    .to(mascotCooksArmR, mascotCooksBounceDur, { morphSVG: mascotCooksArmR, ease: Quad.easeIn }, mascotCooksBounceDur + 0.4)

    .to([mascotCooksEyeL, mascotCooksEyeR], mascotCooksBounceDur + 0.2, { x: 3, y: -2, ease: Quad.easeOut }, "0")
    .to([mascotCooksEyeL, mascotCooksEyeR], mascotCooksBounceDur + 0.2, { x: 0, y: 0, ease: Quad.easeIn }, mascotCooksBounceDur + 0.2)

    .to(mascotCooksDough, 0.5, { y: 0, morphSVG: mascotCooksDough3, ease: Quad.easeOut }, "1")
    .to(mascotCooksDough, 0.5, { y: 0, morphSVG: mascotCooksDough, ease: Quad.easeIn }, "1.5")
    .to(mascotCooksHandL, 0.5, { y: -43, ease: Quad.easeOut }, "1")
    .to(mascotCooksSleeveL, 0.5, { morphSVG: mascotCooksArmL3, ease: Quad.easeOut }, "1")
    .to(mascotCooksArmL, 0.5, { morphSVG: mascotCooksArmL3, ease: Quad.easeOut }, "1")
    .to(mascotCooksHandL, 0.5, { y: 0, ease: Quad.easeIn }, "1.5")
    .to(mascotCooksSleeveL, 0.5, { morphSVG: mascotCooksSleeveL, ease: Quad.easeIn }, "1.5")
    .to(mascotCooksArmL, 0.5, { morphSVG: mascotCooksArmL, ease: Quad.easeIn }, "1.5")
    .to(mascotCooksHandR, 0.5, { y: -43, ease: Quad.easeOut }, "1")
    .to(mascotCooksSleeveR, 0.5, { morphSVG: mascotCooksArmR3, ease: Quad.easeOut }, "1")
    .to(mascotCooksArmR, 0.5, { morphSVG: mascotCooksArmR3, ease: Quad.easeOut }, "1")
    .to(mascotCooksHandR, 0.5, { y: 0, ease: Quad.easeIn }, "1.5")
    .to(mascotCooksSleeveR, 0.5, { morphSVG: mascotCooksSleeveR, ease: Quad.easeIn }, "1.5")
    .to(mascotCooksArmR, 0.5, { morphSVG: mascotCooksArmR, ease: Quad.easeIn }, "1.5")
    .to([mascotCooksEyeL, mascotCooksEyeR], 0.5, { x: 3, y: -16, ease: Quad.easeOut }, "1")
    .to([mascotCooksEyeL, mascotCooksEyeR], 0.5, { x: 0, y: 0, ease: Quad.easeIn }, "1.5")

    .to(mascotCooksDough, 0.15, { y: 6, ease: Quad.easeOut }, "2")
    .to(mascotCooksDough, 0.15, { y: 0, ease: Quad.easeIn }, "2.15")
    .to(mascotCooksHandL, 0.15, { y: 6, ease: Quad.easeOut }, "2")
    .to(mascotCooksSleeveL, 0.15, { morphSVG: mascotCooksArmL4, ease: Quad.easeOut }, "2")
    .to(mascotCooksArmL, 0.15, { morphSVG: mascotCooksArmL4, ease: Quad.easeOut }, "2")
    .to(mascotCooksHandL, 0.15, { y: 0, ease: Quad.easeIn }, "2.15")
    .to(mascotCooksSleeveL, 0.15, { morphSVG: mascotCooksSleeveL, ease: Quad.easeIn }, "2.15")
    .to(mascotCooksArmL, 0.15, { morphSVG: mascotCooksArmL, ease: Quad.easeIn }, "2.15")
    .to(mascotCooksHandR, 0.15, { y: 6, ease: Quad.easeOut }, "2")
    .to(mascotCooksSleeveR, 0.15, { morphSVG: mascotCooksArmR4, ease: Quad.easeOut }, "2")
    .to(mascotCooksArmR, 0.15, { morphSVG: mascotCooksArmR4, ease: Quad.easeOut }, "2")
    .to(mascotCooksHandR, 0.15, { y: 0, ease: Quad.easeIn }, "2.15")
    .to(mascotCooksSleeveR, 0.15, { morphSVG: mascotCooksSleeveR, ease: Quad.easeIn }, "2.15")
    .to(mascotCooksArmR, 0.15, { morphSVG: mascotCooksArmR, ease: Quad.easeIn }, "2.15")
    .to([mascotCooksEyeL, mascotCooksEyeR], 0.15, { x: 0, y: 2, ease: Quad.easeOut }, "2")
    .to([mascotCooksEyeL, mascotCooksEyeR], 0.15, { x: 0, y: 0, ease: Quad.easeIn }, "2.15");

  mascotCooksTL.play();
}

function initMascotCooks() {
  if (typeof TweenMax !== 'undefined') {
    initMascotCooksAnimation();
  }
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initMascotCooks);
} else {
  initMascotCooks();
}
