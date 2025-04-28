const customKeywords = [
  "move",
  "left",
  "right",
  "up",
  "down",
  "if",
  "else",
  "let",
  "while",
  "for",
  "true",
  "false",
  "and",
  "or",
  "peek",
  "attack",
  "stone",
  "wood",
  "open",
  "enemy",
  "border",
  "storm",
  "trap",
];

editor = CodeMirror.fromTextArea(document.getElementById("code"), {
  mode: {
    name: "javascript",
    extraKeywords: customKeywords.join(" "),
  },
  theme: "dracula",
  lineNumbers: true,
  tabSize: 2,
  indentUnit: 2,
  lineWrapping: true,
  autoCloseBrackets: true,
  extraKeys: {
    Tab: (cm) => {
      if (cm.somethingSelected()) cm.indentSelection("add");
      else cm.execCommand("insertSoftTab");
    },
    "Ctrl-Space": "autocomplete",
  },
  gutters: ["CodeMirror-linenumbers"],
});

editor.on("inputRead", (cm, input) => {
  if (input.text && input.text[0].trim()) {
    CodeMirror.commands.autocomplete(cm, null, {
      completeSingle: false,
      hint: () => {
        const cur = cm.getCursor();
        const token = cm.getTokenAt(cur);
        const word = token.string;
        const list = customKeywords
          .filter((kw) => kw.startsWith(word))
          .map((kw) => ({ text: kw }));

        return {
          list: list,
          from: CodeMirror.Pos(cur.line, token.start),
          to: CodeMirror.Pos(cur.line, token.end),
        };
      },
    });
  }
});

