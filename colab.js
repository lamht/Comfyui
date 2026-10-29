//credit - https://huggingface.co/blog/fine-tune-wav2vec2-english (Patrick von Platen)

// run this on your Chrome / Browser Console (where Colab is present) 

function ConnectButton(){
    console.log("Connect pushed"); 
    document.querySelector("#top-toolbar > colab-connect-button").shadowRoot.querySelector("#connect").click() 
}

var colab = setInterval(ConnectButton,60000);

// uncomment the below line and use it for clearing

//clearInterval(colab)