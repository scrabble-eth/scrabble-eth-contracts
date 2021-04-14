const csv = require("csv-parser");
const fs = require("fs");

var words = [];

function getWords() {
    var rowCount = 1;

    fs.createReadStream('testwordlist.csv')
    .pipe(csv())
    .on('data', (row) => {
        if(rowCount > 0)
            words.push([rowCount, row["word"], parseInt(row["points"]), parseInt(row["count"]), parseInt(row["category"])]);
        rowCount++;
    })
    .on('end', () => {
        console.log('CSV file successfully processed.');
    });
}

async function main() {
    const contract = "0xe26C8a6B44579244dBEA6E85D24a972b783a6F96";
    const WordToken = await ethers.getContractFactory("WordToken");
    const wordToken = await WordToken.attach(contract);

    for(var i=0; i < words.length; i++) {
        var word = words[i];
        var result = await wordToken.setCards(word[0], word[1], word[2], word[3], word[4]);
        if(!result) console.log("ERROR:", word[0], result);
        else console.log("ADD:", word[0], result);
    }
}
  
getWords();
main()
.then(() => process.exit(0))
.catch((error) => {
    console.error(error);
    process.exit(1);
});
  