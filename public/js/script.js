//funktion för att fråga användaren innan man omderigeras
function confirmAction(event, prompt, url) {
  event.preventDefault(); //Förhindra eventets standardbeteende(, eventet får inga förinställda saker?)
  if (confirm(prompt)) {
    // Ifall användare klic
    window.location.href = url;
  }
}

setTimeout(function () {
  document.querySelector(".flash").style.display = "none";
}, 2000);

document.addEventListener("DOMContentLoaded", function() {
  // Funktion för att toggla synlighet
  function toggleVisibility() {
    var checkbox = document.getElementById('toggleMDCheckbox');
    var divToToggle = document.getElementById('MDContent');

    // Kontrollerar om kryssrutan är ikryssad och ändrar om den syns eller inte
    if(checkbox.checked) {
      divToToggle.style.display = 'block';
    } else {
      divToToggle.style.display = 'none';
    }
  }

  // Lägger till eventlyssnare för kryssrutan
  document.getElementById('toggleMDCheckbox').addEventListener('change', toggleVisibility);
});

