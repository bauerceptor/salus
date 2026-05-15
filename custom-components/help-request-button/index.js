console.clear();

let helpButton, helpButtonBounds;

function helpButtonClick(e) {
	// get text elements	
	let pressedLabel = e.currentTarget.querySelector('.helpButton--pressedLabel');
	let unpressedLabel = e.currentTarget.querySelector('.helpButton--unpressedLabel');
	
	if(e.currentTarget.getAttribute('aria-pressed')=='true') {
		// make correct text visible
		pressedLabel.classList.add('visuallyHidden');
		unpressedLabel.classList.remove('visuallyHidden');
		
		// update button semantics
		helpButton.setAttribute('aria-pressed',false);
	} else {
		// make correct text visible
		pressedLabel.classList.remove('visuallyHidden');
		unpressedLabel.classList.add('visuallyHidden');
		
		// update button semantics
		helpButton.setAttribute('aria-pressed',true);
	}
	
	helpButtonUpdate();
}

function helpButtonUpdate() {
	// get new measurements
	let newBounds = helpButton.getBoundingClientRect();
	
	// update css vars
	helpButton.style.setProperty('--w',newBounds.width);
	helpButtonBounds = newBounds;
}

function init() {
	// get button element
	helpButton = document.querySelector('.helpButton');
	// get measurements
	helpButtonBounds = helpButton.getBoundingClientRect();
	// update button initially	
	helpButtonUpdate();
	// add click handler
	helpButton.addEventListener('click',helpButtonClick);
}

window.addEventListener('DOMContentLoaded', function() {
	init();
});