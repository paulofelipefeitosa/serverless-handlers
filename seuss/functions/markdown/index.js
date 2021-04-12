function main(args) {
    bld = new Date().getTime();

    var showdown = require('showdown');
    var fs = require('fs');

    var text = fs.readFileSync('./nodejsActionBase/README.md', 'utf-8').toString();

    ald = new Date().getTime();

    var converter = new showdown.Converter();
    html = converter.makeHtml(text);
    ahf = new Date().getTime();
    return {BLD: bld, ALD: ald, AHF: ahf, HTML: html.substr(0, 10)};
}