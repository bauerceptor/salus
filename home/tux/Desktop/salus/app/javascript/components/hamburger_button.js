// _hamburger_button.js
document.addEventListener('DOMContentLoaded', function() {
  var trigger = document.getElementById('hamburger');

  if (trigger) {
    trigger.addEventListener('click', function() {
      if (trigger.classList.contains('is-closed')) {
        trigger.classList.remove('is-closed');
        trigger.classList.add('is-open');
      } else {
        trigger.classList.remove('is-open');
        trigger.classList.add('is-closed');
      }
    });
  }
});