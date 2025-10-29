module JavaAnalysis

import lang::java::m3::Core;
import lang::java::m3::AST;
import IO;
import List;
import Set;
import String;
import Map;

public list[Declaration] getASTs(loc projectLocation) {
    M3 model = createM3FromMavenProject(projectLocation);
    list[Declaration] asts = [createAstFromFile(f, true)
                              | f <- files(model.containment), isCompilationUnit(f)];
    return asts;
}

int getNumberOfInterfaces(list[Declaration] asts){
    int interfaces = 0;
    visit(asts){
        case \interface(_, _, _, _, _, _): interfaces += 1;
    }
    return interfaces;
} 

int getNumberOfForLoops(list[Declaration] asts){
    int forLoops = 0;
    visit(asts){
        case \for(_, _, _, _): forLoops += 1;
    }
    return forLoops;
}

tuple[int, list[str]] mostOccurringVariables(list[Declaration] asts){
    map[str,int] counts = ();

    visit(asts){
        // int a, b[], c = 1;
        case \variable(\id(n), _, _): {
            counts[n] = (n in counts ? counts[n] + 1 : 1);
        }
    }

    int maxCount = 0;
    list[str] most = [];
    for (str n <- domain(counts)) {
        int c = counts[n];
        if (c > maxCount) { maxCount = c; most = [n]; }
        else if (c == maxCount) { most += [n]; }
    }
    return <maxCount, most>;
}

tuple[int, list[str]] mostOccurringNumber(list[Declaration] asts){
    map[str,int] counts = ();

    visit(asts){
        case \number(str numberValue): {
            counts[numberValue] = (numberValue in counts ? counts[numberValue] + 1 : 1);
        }
    }

    int maxCount = 0;
    list[str] most = [];
    for (str n <- domain(counts)) {
        int c = counts[n];
        if (c > maxCount) { maxCount = c; most = [n]; }
        else if (c == maxCount) { most += [n]; }
    }
    return <maxCount, most>;
}

list[loc] findNullReturned(list[Declaration] asts){
    list[loc] nullReturns = [];

    visit(asts){
        // bind the entire return statement node to variable `ret`
        // case ret:\return(\null()): {
        //     if (ret has src) {
        //         nullReturns += [ret@src];
        //     }
        // }
        case \return(\null(), src=L): {
            // L : loc
            nullReturns += [L];
        }
    }
    return nullReturns;
}



int main(int testArgument=0) {
    println("argument: <testArgument>");

    ast = getASTs(|project://smallsql0.21_src/|);

    int interfaces = getNumberOfInterfaces(ast);
    println("Number of interfaces: <interfaces>");

    int forLoops = getNumberOfForLoops(ast);
    println("Number of for loops: <forLoops>");

    tuple[int, list[str]] mostFrequentVars = mostOccurringVariables(ast);
    println("Most occurring variables: <mostFrequentVars>");

    tuple[int, list[str]] mostFrequentNumbers = mostOccurringNumber(ast);
    println("Most occurring numbers: <mostFrequentNumbers>");

    for (loc L <- findNullReturned(ast)) {
        println("return null at <L.path>:<L.begin.line>");
    }


    return testArgument;
}


test bool numberOfInterfaces() {
    return getNumberOfInterfaces(getASTs(|project://smallsql0.21_src|)) == 1;
}