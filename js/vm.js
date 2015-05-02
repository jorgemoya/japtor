function VM(yy) {
    var mems = [];
    var procs = yy.procs;
    var quads = yy.quads;
    var consts = yy.consts;
    var cont = 0;
    var params = [];
    var paramsProc = [];
    var tempProc = null;
    var expectsReturn = [];
    var returns = [];
    var returnedValue = [];

    var globalMem = new Mem(procs[0].dirs());
    mems.push(globalMem);

    while (cont < quads.length) {
        switch (quads[cont][0]) {
            case 'goto':
                cont = quads[cont][3];
                break;

            case 'gotof':
                if (findValue(quads[cont][1])) {
                    cont++;
                } else {
                    cont = quads[cont][3];
                }
                break;

            case 'era':
                var proc_dir = quads[cont][1];
                for (var i = 0; i < procs.length; i++) {
                    if (proc_dir === procs[i].dir) {
                        tempProc = new Mem(procs[i].dirs());
                        paramsProc = procs[i].params;
                    }
                }
                params = [];
                cont++;
                break;

            case 'param':
                var dir = quads[cont][1];
                params.push(findValue(dir));
                cont++;
                break;

            case 'gosub':
                mems.push(tempProc);
                tempProc = null;
                for (var i = 0; i <  params.length; i++) {
                    insertValue(paramsProc[i].dir, params[i]);
                }

                if (quads[cont][3] !== null) {
                    expectsReturn.push(quads[cont][3]);
                } else {
                    expectsReturn.push(false);
                }
                returns.push(cont + 1);
                cont = quads[cont][1];
                break;

            case 'return':
                var dir = quads[cont][3];
                if (dir !== null) {
                    var value = findValue(dir);
                    mems.pop();
                    cont = returns.pop();
                    dir = expectsReturn.pop();
                    if (dir !== false) {
                        insertValue(dir, value);
                    } else {
                    alert("Error returned value wasn't expecting.");
                    }
                } else {
                    mems.pop();
                    cont = returns.pop();
                    dir = expectsReturn.pop();
                    if (dir !== false) {
                        alert("Error expecting return value.")
                    }
                }
                break;

            case 'write':
                var value_dir = quads[cont][3];
                console.log(findValue(value_dir));
                cont++;
                break;

            case '=':
                var value_dir = quads[cont][1];
                var dir = quads[cont][3];
                insertValue(dir, findValue(value_dir));
                cont++;
                break;

            case '+':
                var value1 = findValue(quads[cont][1]);
                var value2 = findValue(quads[cont][2]);
                var dir = quads[cont][3];
                insertValue(dir, value1 + value2);
                cont++;
                break;

            case '-':
                var value1 = findValue(quads[cont][1]);
                var value2 = findValue(quads[cont][2]);
                var dir = quads[cont][3];
                insertValue(dir, value1 - value2);
                cont++;
                break;

            case '*':
                var value1 = findValue(quads[cont][1]);
                var value2 = findValue(quads[cont][2]);
                var dir = quads[cont][3];
                insertValue(dir, value1 * value2);
                cont++;
                break;

            case '/':
                var value1 = findValue(quads[cont][1]);
                var value2 = findValue(quads[cont][2]);
                var dir = quads[cont][3];
                insertValue(dir, value1 / value2);
                cont++;
                break;

            case '==':
                var value1 = findValue(quads[cont][1]);
                var value2 = findValue(quads[cont][2]);
                var dir = quads[cont][3];
                insertValue(dir, value1 === value2);
                cont++;
                break;

            case '>=':
                var value1 = findValue(quads[cont][1]);
                var value2 = findValue(quads[cont][2]);
                var dir = quads[cont][3];
                insertValue(dir, value1 >= value2);
                cont++;
                break;

            case '<=':
                var value1 = findValue(quads[cont][1]);
                var value2 = findValue(quads[cont][2]);
                var dir = quads[cont][3];
                insertValue(dir, value1 <= value2);
                cont++;
                break;

            case '!=':
                var value1 = findValue(quads[cont][1]);
                var value2 = findValue(quads[cont][2]);
                var dir = quads[cont][3];
                insertValue(dir, value1 !== value2);
                cont++;
                break;

            case '>':
                var value1 = findValue(quads[cont][1]);
                var value2 = findValue(quads[cont][2]);
                var dir = quads[cont][3];
                insertValue(dir, value1 > value2);
                cont++;
                break;

            case '<':
                var value1 = findValue(quads[cont][1]);
                var value2 = findValue(quads[cont][2]);
                var dir = quads[cont][3];
                insertValue(dir, value1 < value2);
                cont++;
                break;
        }
    }

    function Mem(startDirs) {
        this.int = [];
        this.float = [];
        this.string = [];
        this.boolean = [];
        this.int_t = [];
        this.float_t = [];
        this.string_t = [];
        this.boolean_t = [];
        this.startDirs = startDirs;
    }

    function findScope(value) {
        if (value >= 5000 && value < 12000) {
            return "global";
        } else if (value >= 12000 && value < 19000) {
            return "local";
        } else if (value >= 19000 && value < 26000) {
            return "temporal";
        } else if (value >= 26000 && value < 33000) {
            return "constant";
        }
        return "noscope";
    }

    function findType(value, scope) {
        if (scope === "global") {
            if (value < 7000)
                return "int";
            else if (value < 9000)
                return "float";
            else if (value < 11000)
                return "string";
            else if (value < 12000)
                return "boolean";
        } else if (scope === "local") {
            if (value < 14000)
                return "int";
            else if (value < 16000)
                return "float";
            else if (value < 18000)
                return "string";
            else if (value < 19000)
                return "boolean";
        } else if (scope === "temporal") {
            if (value < 21000)
                return "int_t";
            else if (value < 23000)
                return "float_t";
            else if (value < 25000)
                return "string_t";
            else if (value < 26000)
                return "boolean_t";
        } else if (scope === "constant") {
            if (value < 28000)
                return "int";
            else if (value < 30000)
                return "float";
            else if (value < 32000)
                return "string";
            else if (value < 33000)
                return "boolean";
        }
        return "notype";
    }

    function findValue(dir) {
        var dir_scope = findScope(dir);
        var dir_type = findType(dir, dir_scope);

        if (dir_scope === "constant") {
            for (var i = 0; i < consts.length; i++) {
                if (consts[i][1] === dir) {
                    return consts[i][0];
                }
            }
        }

        if (dir_scope === "local") {
            if (dir_type === "int")
                return mems[mems.length-1].int[mems[mems.length-1].startDirs[0]-dir];
            else if (dir_type === "float")
                return mems[mems.length-1].float[mems[mems.length-1].startDirs[1]-dir];
            else if (dir_type === "string")
                return mems[mems.length-1].string[mems[mems.length-1].startDirs[2]-dir];
            else if (dir_type === "boolean")
                return mems[mems.length-1].boolean[mems[mems.length-1].startDirs[3]-dir];
        }

        if (dir_scope === "temporal") {
            if (dir_type === "int_t")
                return mems[mems.length-1].int_t[mems[mems.length-1].startDirs[4]-dir];
            else if (dir_type === "float_t")
                return mems[mems.length-1].float_t[mems[mems.length-1].startDirs[5]-dir];
            else if (dir_type === "string_t")
                return mems[mems.length-1].string_t[mems[mems.length-1].startDirs[6]-dir];
            else if (dir_type === "boolean_t")
                return mems[mems.length-1].boolean_t[mems[mems.length-1].startDirs[7]-dir];
        }

        if (dir_scope === "global") {
            if (dir_type === "int")
                return mems[0].int[mems[0].startDirs[0]-dir];
            else if (dir_type === "float")
                return mems[0].float[mems[0].startDirs[1]-dir];
            else if (dir_type === "string")
                return mems[0].string[mems[0].startDirs[2]-dir];
            else if (dir_type === "boolean")
                return mems[0].boolean[mems[0].startDirs[3]-dir];
        }
    }

    function insertValue(dir, value) {
        var dir_scope = findScope(dir);
        var dir_type = findType(dir, dir_scope);

        if (dir_scope === "local") {
            if (dir_type === "int")
                mems[mems.length-1].int[mems[mems.length-1].startDirs[0]-dir] = value;
            else if (dir_type === "float")
                mems[mems.length-1].float[mems[mems.length-1].startDirs[1]-dir] = value;
            else if (dir_type === "string")
                mems[mems.length-1].string[mems[mems.length-1].startDirs[2]-dir] = value;
            else if (dir_type === "boolean")
                mems[mems.length-1].boolean[mems[mems.length-1].startDirs[3]-dir] = value;
        }

        if (dir_scope === "temporal") {
            if (dir_type === "int_t")
                mems[mems.length-1].int_t[mems[mems.length-1].startDirs[4]-dir] = value;
            else if (dir_type === "float_t")
                mems[mems.length-1].float_t[mems[mems.length-1].startDirs[5]-dir] = value;
            else if (dir_type === "string_t")
                mems[mems.length-1].string_t[mems[mems.length-1].startDirs[6]-dir] = value;
            else if (dir_type === "boolean_t")
                mems[mems.length-1].boolean_t[mems[mems.length-1].startDirs[7]-dir] = value;
        }

        if (dir_scope === "global") {
            if (dir_type === "int")
                mems[0].int[mems[0].startDirs[0]-dir] = value;
            else if (dir_type === "float")
                mems[0].float[mems[0].startDirs[1]-dir] = value;
            else if (dir_type === "string")
                mems[0].string[mems[0].startDirs[2]-dir] = value;
            else if (dir_type === "boolean")
                mems[0].boolean[mems[0].startDirs[3]-dir] = value;
        }
    }
}
