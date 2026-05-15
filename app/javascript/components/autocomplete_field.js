// Autocomplete Form Field Component
// Transforms a select element into an accessible autocomplete input

function Autocomplete(select, shortcuts, shortcutText) {
  this.select = select;
  this.container = select.parentElement;

  if (shortcuts) {
    this.shortcuts = shortcuts;
    this.shortcutText = shortcutText;
    this.createShortcuts();
  }

  this.wrapper = document.createElement("div");
  this.wrapper.classList.add("autocomplete");
  this.wrapper.id = this.select.name + "-autocomplete";
  this.container.appendChild(this.wrapper);

  this.createTextBox();
  this.createArrowIcon();
  this.createMenu();
  this.hideSelectBox();
  this.createStatusBox();
  this.setupKeys();
  this.setMenuHeight();

  document.addEventListener("click", this.onDocumentClick.bind(this));
}

Autocomplete.prototype.onDocumentClick = function(e) {
  if (!this.container.contains(e.target)) {
    this.hideMenu();
    this.removeTextBoxFocus();
  }
};

Autocomplete.prototype.setupKeys = function() {
  this.keys = {
    enter: 13,
    esc: 27,
    space: 32,
    up: 38,
    down: 40,
    tab: 9,
    left: 37,
    right: 39,
    shift: 16
  };
};

Autocomplete.prototype.onTextBoxFocus = function() {
  this.textBox.classList.add("autocomplete-isFocused");
};

Autocomplete.prototype.removeTextBoxFocus = function() {
  this.textBox.classList.remove("autocomplete-isFocused");
};

Autocomplete.prototype.onTextBoxClick = function(e) {
  this.clearOptions();
  var options = this.getAllOptions();
  this.buildMenu(options);
  this.updateStatus(options.length);
  this.showMenu();
  if (typeof e.currentTarget.select === "function") {
    e.currentTarget.select();
  }
};

Autocomplete.prototype.onTextBoxKeyUp = function(e) {
  switch (e.keyCode) {
    case this.keys.esc:
    case this.keys.up:
    case this.keys.left:
    case this.keys.right:
    case this.keys.space:
    case this.keys.enter:
    case this.keys.tab:
    case this.keys.shift:
      break;
    case this.keys.down:
      this.onTextBoxDownPressed(e);
      break;
    default:
      this.onTextBoxType(e);
  }
};

Autocomplete.prototype.onMenuKeyDown = function(e) {
  switch (e.keyCode) {
    case this.keys.up:
      this.onOptionUpArrow(e);
      break;
    case this.keys.down:
      this.onOptionDownArrow(e);
      break;
    case this.keys.enter:
      this.onOptionEnter(e);
      break;
    case this.keys.space:
      this.onOptionSpace(e);
      break;
    case this.keys.esc:
      this.onOptionEscape(e);
      break;
    case this.keys.tab:
      this.hideMenu();
      this.removeTextBoxFocus();
      break;
    default:
      this.textBox.focus();
  }
};

Autocomplete.prototype.onTextBoxType = function(e) {
  if (this.textBox.value.trim().length > 0) {
    var options = this.getOptions(this.textBox.value.trim().toLowerCase());
    this.buildMenu(options);
    this.showMenu();
    this.updateStatus(options.length);
  } else {
    this.hideMenu();
  }
  this.updateSelectBox();
};

Autocomplete.prototype.updateSelectBox = function() {
  var value = this.textBox.value.trim();
  var option = this.getMatchingOption(value);
  if (option) {
    this.select.value = option.value;
  } else {
    this.select.value = "";
  }
};

Autocomplete.prototype.onOptionEscape = function(e) {
  this.clearOptions();
  this.hideMenu();
  this.focusTextBox();
};

Autocomplete.prototype.focusTextBox = function() {
  this.textBox.focus();
};

Autocomplete.prototype.onOptionEnter = function(e) {
  if (this.isOptionSelected()) {
    this.selectActiveOption();
  }
  e.preventDefault();
};

Autocomplete.prototype.onOptionSpace = function(e) {
  if (this.isOptionSelected()) {
    this.selectActiveOption();
    e.preventDefault();
  }
};

Autocomplete.prototype.onOptionClick = function(e) {
  var option = e.target;
  this.selectOption(option);
};

Autocomplete.prototype.selectActiveOption = function() {
  var option = this.getActiveOption();
  this.selectOption(option);
};

Autocomplete.prototype.selectOption = function(option) {
  var value = option.getAttribute("data-option-value");
  this.setValue(value);
  this.hideMenu();
  this.focusTextBox();
};

Autocomplete.prototype.onTextBoxDownPressed = function(e) {
  var option;
  var options;
  var value = this.textBox.value.trim();

  if (value.length === 0 || this.isExactMatch(value)) {
    options = this.getAllOptions();
    this.buildMenu(options);
    this.showMenu();
    option = this.getFirstOption();
    this.highlightOption(option);
  } else {
    options = this.getOptions(value);
    if (options.length > 0) {
      this.buildMenu(options);
      this.showMenu();
      option = this.getFirstOption();
      this.highlightOption(option);
    }
  }
};

Autocomplete.prototype.onOptionDownArrow = function(e) {
  var option = this.getNextOption();
  if (option) {
    this.highlightOption(option);
  }
  e.preventDefault();
};

Autocomplete.prototype.onOptionUpArrow = function(e) {
  if (this.isOptionSelected()) {
    option = this.getPreviousOption();
    if (option) {
      this.highlightOption(option);
    } else {
      this.focusTextBox();
      this.hideMenu();
    }
  }
  e.preventDefault();
};

Autocomplete.prototype.isOptionSelected = function() {
  return this.activeOptionId;
};

Autocomplete.prototype.getActiveOption = function() {
  return document.querySelector("#" + this.activeOptionId);
};

Autocomplete.prototype.getFirstOption = function() {
  return this.menu.querySelector("li:first-of-type");
};

Autocomplete.prototype.getPreviousOption = function() {
  return document.querySelector("#" + this.activeOptionId).previousSibling;
};

Autocomplete.prototype.getNextOption = function() {
  return document.querySelector("#" + this.activeOptionId).nextSibling;
};

Autocomplete.prototype.highlightOption = function(option) {
  if (this.activeOptionId) {
    var activeOption = this.getOptionById(this.activeOptionId);
    activeOption.setAttribute("aria-selected", "false");
  }

  option.setAttribute("aria-selected", "true");

  if (!this.isElementVisible(this.menu, option)) {
    this.menu.scrollTop = option.offsetTop;
  }

  this.activeOptionId = option.id;
  option.focus();
};

Autocomplete.prototype.getOptionById = function(id) {
  return document.querySelector("#" + id);
};

Autocomplete.prototype.showMenu = function() {
  this.menu.classList.remove("hidden");
  this.textBox.setAttribute("aria-expanded", "true");
  this.setMenuHeight();
  var self = this;
  setTimeout(function() {
    self.wrapper.classList.add("autocomplete-focusWithin");
  }, 1);
};

Autocomplete.prototype.hideMenu = function() {
  this.wrapper.classList.remove("autocomplete-focusWithin");
  this.menu.classList.add("hidden");
  this.textBox.setAttribute("aria-expanded", "false");
  this.activeOptionId = null;
  this.clearOptions();
};

Autocomplete.prototype.clearOptions = function() {
  var toRemove = this.menu.querySelectorAll("*");
  toRemove.forEach(function(n) {
    return n.remove();
  });
};

Autocomplete.prototype.getOptions = function(value) {
  var matches = [];
  var self = this;
  this.select.querySelectorAll("option").forEach(function(el) {
    if (
      (el.value.trim().length > 0 &&
        el.textContent.toLowerCase().indexOf(value.toLowerCase()) > -1) ||
      (el.getAttribute("data-alt") &&
        el.getAttribute("data-alt").toLowerCase().indexOf(value.toLowerCase()) > -1)
    ) {
      matches.push({
        text: el.textContent,
        value: el.value
      });
    }
  });
  return matches;
};

Autocomplete.prototype.getAllOptions = function() {
  var filtered = [];
  var options = this.select.querySelectorAll("option");
  var option;
  for (var i = 0; i < options.length; i++) {
    option = options[i];
    var value = option.value;
    if (value.trim().length > 0) {
      filtered.push({
        text: option.textContent,
        value: option.value
      });
    }
  }
  return filtered;
};

Autocomplete.prototype.isExactMatch = function(value) {
  return this.getMatchingOption(value);
};

Autocomplete.prototype.getMatchingOption = function(value) {
  var option = null;
  var options = this.select.querySelectorAll("option");
  for (var i = 0; i < options.length; i++) {
    if (options[i].textContent.toLowerCase() === value.toLowerCase()) {
      option = options[i];
      break;
    }
  }
  return option;
};

Autocomplete.prototype.buildMenu = function(options) {
  this.clearOptions();
  this.activeOptionId = null;

  var fragment = document.createDocumentFragment();

  if (options.length) {
    for (var i = 0; i < options.length; i++) {
      fragment.appendChild(this.getOptionHtml(i, options[i]));
    }
  } else {
    fragment.appendChild(this.getNoResultsOptionHtml());
  }

  this.menu.appendChild(fragment);
  this.menu.scrollTop = this.menu.scrollTop;
};

Autocomplete.prototype.setMenuHeight = function() {
  this.menuHeight = this.menu.offsetHeight;
  this.menuHeight = this.menu.getBoundingClientRect().height;
  this.menuMaxHeight = getComputedStyle(this.menu).maxHeight;
  this.menuMaxHeight = this.menuMaxHeight.substring(0, this.menuMaxHeight.length - 2);

  if (this.menuHeight == 0) {
    var h = (this.menuHeight = this.menuMaxHeight);
  } else {
    var h = this.menuHeight;
  }

  this.wrapper.style.setProperty("--listbox-h", h + "px");
};

Autocomplete.prototype.getNoResultsOptionHtml = function() {
  var fragment = document.createDocumentFragment();
  var li = document.createElement("li");
  li.classList.add("autocomplete-optionNoResults");
  li.textContent = "No results";
  fragment.appendChild(li);
  return fragment;
};

Autocomplete.prototype.getOptionHtml = function(i, option) {
  var fragment = document.createDocumentFragment();
  var li = document.createElement("li");
  li.id = "autocomplete-option--" + i;
  li.setAttribute("tabindex", "-1");
  li.setAttribute("aria-selected", "false");
  li.setAttribute("role", "option");
  li.setAttribute("data-option-value", option.value);
  li.textContent = option.text;
  fragment.appendChild(li);
  return fragment;
};

Autocomplete.prototype.createStatusBox = function() {
  this.status = document.createElement("div");
  this.status.setAttribute("aria-live", "polite");
  this.status.setAttribute("role", "status");
  this.status.classList.add("visually-hidden");
  this.wrapper.appendChild(this.status);
};

Autocomplete.prototype.updateStatus = function(result) {
  if (result === 0) {
    this.status.textContent = "No results.";
  } else {
    this.status.textContent = result + " results available.";
  }
};

Autocomplete.prototype.hideSelectBox = function() {
  this.select.setAttribute("aria-hidden", "true");
  this.select.setAttribute("tabindex", "-1");
  this.select.classList.add("visually-hidden");
  this.select.removeAttribute("id");
};

Autocomplete.prototype.createTextBox = function() {
  this.textBox = document.createElement("input");
  this.textBox.setAttribute("type", "text");
  this.textBox.setAttribute("autocapitalize", "none");
  this.textBox.setAttribute("autocomplete", "off");
  this.textBox.setAttribute("aria-owns", this.getOptionsId());
  this.textBox.setAttribute("aria-autocomplete", "list");
  this.textBox.setAttribute("role", "combobox");
  this.textBox.setAttribute("aria-expanded", false);

  this.textBox.id = this.select.id;

  var selectedOption = this.select.selectedOptions[0];
  var selectedVal = selectedOption.value;

  if (selectedVal.trim().length > 0) {
    this.textBox.value = selectedOption.textContent;
  }

  this.wrapper.appendChild(this.textBox);

  var self = this;

  this.textBox.addEventListener("click", this.onTextBoxClick.bind(this));

  this.textBox.addEventListener("keydown", function(e) {
    switch (e.keyCode) {
      case self.keys.tab:
        self.hideMenu();
        self.removeTextBoxFocus();
        break;
      case self.keys.esc:
        self.onOptionEscape(e);
        break;
    }
  });

  this.textBox.addEventListener("keyup", this.onTextBoxKeyUp.bind(this));
  this.textBox.addEventListener("focus", this.onTextBoxFocus.bind(this));
};

Autocomplete.prototype.getOptionsId = function() {
  return "autocomplete-options--" + this.select.id;
};

Autocomplete.prototype.createShortcuts = function() {
  var frag = document.createDocumentFragment();

  this.shortcutWrapper = document.createElement("p");
  this.shortcutWrapper.setAttribute("tabIndex", "0");
  this.shortcutWrapper.classList.add("shortcut");
  this.shortcutWrapper.setAttribute("role", "menubar");
  this.shortcutWrapper.addEventListener("keydown", this.onShortcutKeyDown.bind(this));
  frag.appendChild(this.shortcutWrapper);

  this.shortcutLabel = document.createElement("span");
  this.shortcutLabel.classList.add("shortcut--label");
  this.shortcutLabel.setAttribute("role", "heading");
  this.shortcutLabel.textContent = this.shortcutText;
  this.shortcutLabel.id = this.select.name + "-shortcut--label";
  this.shortcutWrapper.setAttribute("aria-labelledby", this.shortcutLabel.id);
  this.shortcutWrapper.appendChild(this.shortcutLabel);

  for (var i = 0; i < this.shortcuts.length; i++) {
    var option = this.select.querySelector("option:nth-of-type(" + (this.shortcuts[i] + 1) + ")");
    var button = document.createElement("button");
    button.setAttribute("type", "button");
    button.setAttribute("role", "menuitem");
    button.setAttribute("tabindex", "-1");
    button.setAttribute("data-option-value", this.shortcuts[i]);
    button.innerHTML = '<span class="visually-hidden">Enter </span>' + option.textContent;
    button.id = "shortcut--button-" + i;
    button.addEventListener("click", this.onShortcutClick.bind(this));
    this.shortcutWrapper.appendChild(button);
  }

  this.activeShortcutId = "shortcut--button-0";

  this.container.appendChild(frag);
};

Autocomplete.prototype.onShortcutClick = function(e) {
  var value = e.target.getAttribute("data-option-value");
  this.setValue(value);
};

Autocomplete.prototype.onShortcutKeyDown = function(e) {
  switch (e.keyCode) {
    case this.keys.up:
    case this.keys.left:
      this.onShortcutUpArrow(e);
      break;
    case this.keys.down:
    case this.keys.right:
      this.onShortcutDownArrow(e);
      break;
    case this.keys.esc:
      this.onShortcutEsc(e);
      break;
    case this.keys.enter:
      this.onShortcutEnter(e);
      break;
    case this.keys.space:
      this.onShortcutEnter(e);
      break;
  }
};

Autocomplete.prototype.onShortcutEnter = function(e) {
  if (document.activeElement == this.shortcutWrapper) {
    this.onShortcutDownArrow(e);
  }
};

Autocomplete.prototype.onShortcutEsc = function(e) {
  this.shortcutWrapper.focus();
};

Autocomplete.prototype.onShortcutUpArrow = function(e) {
  if (document.activeElement == this.shortcutWrapper) {
    document.querySelector("#" + this.activeShortcutId).focus();
  } else {
    var shortcut = this.getPrevShortcut();
    shortcut.focus();
  }
  e.preventDefault();
};

Autocomplete.prototype.onShortcutDownArrow = function(e) {
  if (document.activeElement == this.shortcutWrapper) {
    document.querySelector("#" + this.activeShortcutId).focus();
  } else {
    var shortcut = this.getNextShortcut();
    shortcut.focus();
  }
  e.preventDefault();
};

Autocomplete.prototype.getPrevShortcut = function() {
  var el;
  var l = this.activeShortcutId.length;
  var num = parseInt(this.activeShortcutId.substring(l - 1, l));
  if (num > 0) {
    num--;
  } else {
    num = this.shortcuts.length - 1;
  }
  el = document.querySelector("#shortcut--button-" + num);
  this.activeShortcutId = el.id;
  return el;
};

Autocomplete.prototype.getNextShortcut = function() {
  var el;
  var l = this.activeShortcutId.length;
  var num = parseInt(this.activeShortcutId.substring(l - 1, l));
  if (num < this.shortcuts.length - 1) {
    num++;
  } else {
    num = 0;
  }
  el = document.querySelector("#shortcut--button-" + num);
  this.activeShortcutId = el.id;
  return el;
};

Autocomplete.prototype.createArrowIcon = function() {
  var ns = "http://www.w3.org/2000/svg";
  var arrow = document.createElementNS(ns, "svg");
  arrow.setAttributeNS(ns, "focusable", "false");
  arrow.setAttributeNS(ns, "version", "1.1");
  arrow.setAttributeNS(ns, "viewBox", "0 0 22 17");
  arrow.setAttributeNS(ns, "width", "16");
  arrow.setAttributeNS(ns, "height", "12");
  arrow.classList.add("field-dropdown--arrow");

  var shape = document.createElementNS(ns, "polygon");
  shape.setAttributeNS(null, "points", "0 0 16 0 8 12");
  arrow.appendChild(shape);
  this.wrapper.appendChild(arrow);

  var arrowEl = document.querySelector(".field-dropdown--arrow");
  arrowEl.addEventListener("click", this.onArrowClick.bind(this));
};

Autocomplete.prototype.onArrowClick = function(e) {
  this.clearOptions();
  var options = this.getAllOptions();
  this.buildMenu(options);
  this.updateStatus(options.length);
  this.showMenu();
  this.textBox.focus();
};

Autocomplete.prototype.createMenu = function() {
  this.menu = document.createElement("ul");
  this.menu.id = this.getOptionsId();
  this.menu.setAttribute("role", "listbox");
  this.menu.classList.add("hidden");
  this.wrapper.appendChild(this.menu);
  this.menu.addEventListener("click", this.onOptionClick.bind(this));
  this.menu.addEventListener("keydown", this.onMenuKeyDown.bind(this));
};

Autocomplete.prototype.isElementVisible = function(container, element) {
  var containerBounds = container.getBoundingClientRect();
  var elementBounds = element.getBoundingClientRect();
  var containerHeight = containerBounds.height;
  var elementTop = elementBounds.top;
  var containerTop = containerBounds.top;
  var elementHeight = elementBounds.height;
  var visible;

  if (
    elementTop - containerTop < 0 ||
    elementTop - containerTop + elementHeight > containerHeight
  ) {
    visible = false;
  } else {
    visible = true;
  }
  return visible;
};

Autocomplete.prototype.getOption = function(value) {
  return this.select.querySelector('option[value="' + value + '"]');
};

Autocomplete.prototype.setValue = function(val) {
  this.select.value = val;
  var text = this.getOption(val).textContent;
  if (val.trim().length > 0) {
    this.textBox.value = text;
    this.status.textContent = text + " entered";
  } else {
    this.textBox.value = "";
  }
};

// Auto-initialize autocomplete fields on DOM ready
var AutocompleteField = (function() {
  function init() {
    var selects = document.querySelectorAll(".autocomplete-field__select");
    selects.forEach(function(select) {
      new Autocomplete(select);
    });
  }

  document.addEventListener("DOMContentLoaded", init);

  return { init: init, Autocomplete: Autocomplete };
})();
