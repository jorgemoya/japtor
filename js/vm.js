function VM(yy) {
    /**
    	Initialize vars
    **/

    var mems = []; // Array with mems
    var procs = yy.procs; // Procs from compilation
    var quads = yy.quads; // Quads from compilation
    var consts = yy.consts; // Consts from compilation
    var cont = 0;
    var params = []; //  Array used for params
    var paramsProc = [];
    var tempProc = null;
    var expectsReturn = [];
    var returns = [];
    var returnedValue = [];
    var result = ""

    // Creates a global mem and adds to stack
    var globalMem = new Mem(procs[0].dirs());
    mems.push(globalMem);

    // Finds the main function and creates mem and adds to stack
    for (var i = 0; i < procs.length; i++) {
        if ("main" === procs[i].name) {
            var mainMem = new Mem(procs[i].dirs());
            mems.push(mainMem);
        }
    }

    // Reads quads
    while (cont < quads.length) {
        switch (quads[cont][0]) {
            case 'goto':
                cont = quads[cont][3]; // Change cont to new value
                break;

            case 'gotof':
                var bool = findValue(quads[cont][1]);
                if (typeof bool === 'string') { // If string converto to bool
                    bool = (bool === 'true');
                }

                if (bool) {
                    cont++; // Continue
                } else {
                    cont = quads[cont][3]; // Change cont to new value
                }
                break;

            case 'era':
                var proc_dir = quads[cont][1];
                for (var i = 0; i < procs.length; i++) {
                    if (proc_dir === procs[i].dir) {
                        // Created new temp proc (not yet added to mems stack)
                        tempProc = new Mem(procs[i].dirs());
                        paramsProc = procs[i].params;
                    }
                }
                params = [];
                cont++;
                break;

            case 'param':
                var dir = quads[cont][1];

                if (typeof dir === "string") { // If param is an array
                    var param = dir.replace(/[()]/g, '');
                    param = param.split(","); // Splits the returned value
                    for(var i = 0; i < parseInt(param[1]); i++) {
                        params.push(findValue(parseInt(param[0]) + i)); // Adds all the params for the array
                    }
                } else {
                    params.push(findValue(dir));
                }
                cont++;
                break;

            case 'gosub':
                mems.push(tempProc); // Pushes tempProc to mems
                tempProc = null;
                for (var i = 0; i <  paramsProc.length; i++) { // For each param
                    if (paramsProc[i].dim > 0) { // If array
                        for(var y = 0; y < paramsProc[i].dim; y++) {
                            insertValue(paramsProc[i].dir + y, params[y + i]);
                        }
                    } else {
                        insertValue(paramsProc[i].dir, params[i]);
                    }
                }

                if (quads[cont][3] !== null) { // If expects return
                    expectsReturn.push(quads[cont][3]);
                } else {
                    expectsReturn.push(false);
                }
                returns.push(cont + 1);
                cont = quads[cont][1];
                break;

            case 'return':
                var dir = quads[cont][3];
                if (dir !== null) { // If returning something
                    var value = findValue(dir); // Value of return
                    mems.pop(); // Exits scope
                    cont = returns.pop();
                    dir = expectsReturn.pop();
                    if (dir !== false) {
                        insertValue(dir, value); // Inserts value
                    } else {
                        throw new Error("EXPECTED RETURN");
                        return;
                    }
                } else { // No return expected
                    mems.pop(); // Exit scope
                    cont = returns.pop();
                    dir = expectsReturn.pop();
                    if (dir !== false) {
                        throw new Error("EXPECTED RETURN");
                        return;
                    }
                }
                break;

            case 'write':
                var value_dir = quads[cont][3];
                console.log(findValue(value_dir));
                result += findValue(value_dir) + "\n"; // Prints the result
                cont++;
                break;

            case 'verify':
                var value = findValue(quads[cont][1], false);
                var lower = quads[cont][2];
                var upper = quads[cont][3];
                if (value < lower || value > upper) { // Verifies the limits
                    throw new Error("OUT OF BOUNDS");
                }
                cont++;
                break;

            case '=':
                var value_dir = quads[cont][1];
                var dir = quads[cont][3];
                insertValue(dir, findValue(value_dir));
                cont++;
                break;

            case '++':
                var value1 = quads[cont][1];
                var value2 = findValue(quads[cont][2], false);
                var dir = parseInt(quads[cont][3].replace(/[()]/g, ''));
                // insertValue(dir, value1 + value2);
                var sum = value1 + value2;
                var found = false;
                if (findScope(sum) == "global") { // If global
                    for(var i = 0; i < mems[0].pointers.length; i++) {
                        if (mems[0].pointers[i][0] == dir) { // Finds pointer
                            mems[0].pointers[i][1] = sum; // Replace pointer with new value
                            found = true;
                        }
                    }

                    if (!found)
                        mems[0].pointers.push([dir, value1 + value2]);
                } else { // If local
                    for(var i = 0; i < mems[mems.length-1].pointers.length; i++) {
                        if (mems[mems.length-1].pointers[i][0] == dir) { // Finds pointer
                            mems[mems.length-1].pointers[i][1] = sum; // Replace pointer with new value
                            found = true;
                        }
                    }
                    if (!found)
                        mems[mems.length-1].pointers.push([dir, value1 + value2]);
                }
                cont++;
                break;

            case '+':
                var value1 = findValue(quads[cont][1]);
                var value2 = findValue(quads[cont][2]);
                var dir = quads[cont][3];
                insertValue(dir, value1 + value2); // Inserts value of +
                cont++;
                break;

            case '-':
                var value1 = findValue(quads[cont][1]);
                var value2 = findValue(quads[cont][2]);
                var dir = quads[cont][3];
                insertValue(dir, value1 - value2); // Inserts value of -
                cont++;
                break;

            case '*':
                var value1 = findValue(quads[cont][1]);
                var value2 = findValue(quads[cont][2]);
                var dir = quads[cont][3];
                insertValue(dir, value1 * value2); // Inserts value of *
                cont++;
                break;

            case '/':
                var value1 = findValue(quads[cont][1]);
                var value2 = findValue(quads[cont][2]);
                var dir = quads[cont][3];
                insertValue(dir, value1 / value2); // Inserts value of /
                cont++;
                break;

            case '==':
                var value1 = findValue(quads[cont][1]);
                var value2 = findValue(quads[cont][2]);
                var dir = quads[cont][3];
                insertValue(dir, value1 === value2); // Inserts value of ==
                cont++;
                break;

            case '>=':
                var value1 = findValue(quads[cont][1]);
                var value2 = findValue(quads[cont][2]);
                var dir = quads[cont][3];
                insertValue(dir, value1 >= value2); // Inserts value of >=
                cont++;
                break;

            case '<=':
                var value1 = findValue(quads[cont][1]);
                var value2 = findValue(quads[cont][2]);
                var dir = quads[cont][3];
                insertValue(dir, value1 <= value2); // Inserts value of <=
                cont++;
                break;

            case '!=':
                var value1 = findValue(quads[cont][1]);
                var value2 = findValue(quads[cont][2]);
                var dir = quads[cont][3];
                insertValue(dir, value1 !== value2); // Inserts value of !=
                cont++;
                break;

            case '>':
                var value1 = findValue(quads[cont][1]);
                var value2 = findValue(quads[cont][2]);
                var dir = quads[cont][3];
                insertValue(dir, value1 > value2); // Inserts value of >
                cont++;
                break;

            case '<':
                var value1 = findValue(quads[cont][1]);
                var value2 = findValue(quads[cont][2]);
                var dir = quads[cont][3];
                insertValue(dir, value1 < value2); // Inserts value of <
                cont++;
                break;

            case '&&':
                var value1 = findValue(quads[cont][1]);
                var value2 = findValue(quads[cont][2]);
                var dir = quads[cont][3];
                insertValue(dir, value1 && value2); // Inserts value of &&
                cont++;
                break;

            case '||':
                var value1 = findValue(quads[cont][1]);
                var value2 = findValue(quads[cont][2]);
                var dir = quads[cont][3];
                insertValue(dir, value1 || value2); // Inserts value of ||
                cont++;
                break;
        }
    }

    return result; // returns the result

    /**
    	Mem Class
    **/

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
        this.pointers = [];
    }

    /**
        Find the scope depending on dir
    **/

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
        throw new Error("NOT FOUND");
    }

    /**
        Find type depending on scope and dir
    **/

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
        throw new Error("NOT FOUND");
    }

    /**
    	Finds value from dir in mems.
        Always checks local scope (mems[mems.length-1]) or global (mems[0])
    **/

    function findValue(dir) {
        var dir_scope = findScope(dir);
        var dir_type = findType(dir, dir_scope);

        // Verifies if it is a pointer
        for (var i = 0; i < mems[mems.length-1].pointers.length; i++) {
            if (dir == mems[mems.length-1].pointers[i][0]) {
                return findValue(mems[mems.length-1].pointers[i][1]); // If pointer find the true value
            }
        }

        // Verifies global pointers
        for (var i = 0; i < mems[0].pointers.length; i++) {
            if (dir == mems[0].pointers[i][0]) {
                return findValue(mems[0].pointers[i][1]);
            }
        }

        // Checks constants
        if (dir_scope === "constant") {
            for (var i = 0; i < consts.length; i++) {
                if (consts[i][1] === dir) {
                    return consts[i][0];
                }
            }
        }

        if (dir_scope === "local") {
            if (dir_type === "int")
                return mems[mems.length-1].int[dir - mems[mems.length-1].startDirs[0]];
            else if (dir_type === "float")
                return mems[mems.length-1].float[dir - mems[mems.length-1].startDirs[1]];
            else if (dir_type === "string")
                return mems[mems.length-1].string[dir - mems[mems.length-1].startDirs[2]];
            else if (dir_type === "boolean")
                return mems[mems.length-1].boolean[dir - mems[mems.length-1].startDirs[3]];
        }

        if (dir_scope === "temporal") {
            if (dir_type === "int_t")
                return mems[mems.length-1].int_t[dir - mems[mems.length-1].startDirs[4]];
            else if (dir_type === "float_t")
                return mems[mems.length-1].float_t[dir - mems[mems.length-1].startDirs[5]];
            else if (dir_type === "string_t")
                return mems[mems.length-1].string_t[dir - mems[mems.length-1].startDirs[6]];
            else if (dir_type === "boolean_t")
                return mems[mems.length-1].boolean_t[dir - mems[mems.length-1].startDirs[7]];
        }

        if (dir_scope === "global") {
            if (dir_type === "int")
                return mems[0].int[dir - mems[0].startDirs[0]];
            else if (dir_type === "float")
                return mems[0].float[dir - mems[0].startDirs[1]];
            else if (dir_type === "string")
                return mems[0].string[dir - mems[0].startDirs[2]];
            else if (dir_type === "boolean")
                return mems[0].boolean[dir - mems[0].startDirs[3]];
        }

        throw new Error("NOT FOUND");
    }

    /**
        Insert Value
        Inserts value in dir.
        Always checks local scope (mems[mems.length-1]) or global (mems[0])
    **/

    function insertValue(dir, value) {
        var dir_scope = findScope(dir);
        var dir_type = findType(dir, dir_scope);

        // Verifies if it is a pointer
        for (var i = 0; i < mems[mems.length-1].pointers.length; i++) {
            if (dir == mems[mems.length-1].pointers[i][0]) {
                insertValue(mems[mems.length-1].pointers[i][1], value); // Insert value in true pointer dir
                return;
            }
        }

        if (dir_scope === "local") {
            if (dir_type === "int")
                mems[mems.length-1].int[dir - mems[mems.length-1].startDirs[0]] = value;
            else if (dir_type === "float")
                mems[mems.length-1].float[dir - mems[mems.length-1].startDirs[1]] = value;
            else if (dir_type === "string")
                mems[mems.length-1].string[dir - mems[mems.length-1].startDirs[2]] = value;
            else if (dir_type === "boolean")
                mems[mems.length-1].boolean[dir - mems[mems.length-1].startDirs[3]] = value;
        }

        if (dir_scope === "temporal") {
            if (dir_type === "int_t")
                mems[mems.length-1].int_t[dir - mems[mems.length-1].startDirs[4]] = value;
            else if (dir_type === "float_t")
                mems[mems.length-1].float_t[dir - mems[mems.length-1].startDirs[5]] = value;
            else if (dir_type === "string_t")
                mems[mems.length-1].string_t[dir - mems[mems.length-1].startDirs[6]] = value;
            else if (dir_type === "boolean_t")
                mems[mems.length-1].boolean_t[dir - mems[mems.length-1].startDirs[7]] = value;
        }

        // Verifies if it is a global pointer
        for (var i = 0; i < mems[0].pointers.length; i++) {
            if (dir == mems[0].pointers[i][0]) {
                insertValue(mems[0].pointers[i][1], value);
                return;
            }
        }

        if (dir_scope === "global") {
            if (dir_type === "int")
                mems[0].int[dir - mems[0].startDirs[0]] = value;
            else if (dir_type === "float")
                mems[0].float[dir - mems[0].startDirs[1]] = value;
            else if (dir_type === "string")
                mems[0].string[dir - mems[0].startDirs[2]] = value;
            else if (dir_type === "boolean")
                mems[0].boolean[dir - mems[0].startDirs[3]] = value;
        }
    }
}
