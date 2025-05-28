# Travelers

Travelers is a robot/cellular automata battle royale where some amount of players fight in a 64x64 grid. The catch: every fighter is a robot controlled from a customized embedded language: FightScript. 

FightScript is a simple C-Style language with looping, conditionals and function declarations. Furthermore, keywords such as `move`, `peek`, `attack` and `trap` allow robots to learn about their environment and attempt to hinder others. 

Robots cannot directly hurt one another, but they can place traps if they have the proper resources, or attack one another, causing the attacked bot to shoot backwards. A storm will slowly encapsulate the entire field, dealing tick damage. The last robot standing will be considered the best program >:)

To train your program for the field, you can test scripts in the dojo, a 32x32 customizable environment where you can add environmental features and test how viable different strategies are. Once you're ready, you can export your script to the battlegrounds and reap your victory.

### Basic Ruls

The rules of `Travelers` are relatively what you would expect, you can move, attack, place traps and peek in all 4 cardinal directions, a quick sample of these features would be:

```c

while (peek right != trap) {
    move right;
    if (peek down == enemy) {
        attack down;
    } else {
        trap down;
    }
}
```

It's important to note how traps work. Robots spawn with 3 wood in their inventory. Placing a trap in any direction costs 3 wood and upon any robot entering the tile with the trap they will receive 20 damage. To gain more wood for traps, you must collect it by attacking wood tiles with `attack {direction}`.

Happy hunting

