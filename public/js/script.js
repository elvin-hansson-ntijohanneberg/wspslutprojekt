//funktion för att fråga användaren innan man omderigeras
function confirmAction(event, prompt, url) {
    event.preventDefault(); //Förhindra eventets standardbeteende(, eventet får inga förinställda saker?)
    if (confirm(prompt)) { // Ifall användare klic
        window.location.href = url;
    }

}