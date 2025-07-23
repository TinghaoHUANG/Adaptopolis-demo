# Adaptopolis

Adaptopolis is a rogue-like city management game where you play as the mayor, defending your city from relentless rain and flooding. Your goal is to build resilient infrastructure, manage your city's health and finances, and survive as many rounds as possible against increasingly severe weather.

## Game Overview
- **Role:** Mayor of a city under constant threat from rain and flooding.
- **Objective:** Keep your city's health above zero by building infrastructure and managing resources.
- **Game Over:** The game ends when your city's health drops below zero.

## Gameplay Mechanics

### City Health & Rain Attacks
- The city starts with a set amount of health (completeness).
- Each round, a rain attack inflicts flood damage, reducing city health.
- If health falls below zero, the game ends.

### Income System
- After each rain attack, the city receives income.
- No damage: maximum income.
- Low damage: slightly reduced income.
- High damage: income decreases further.
- The more damage the city takes, the less income it receives in the next round.

### Infrastructure Cards
- Between rounds, you are dealt 3 random infrastructure cards.
- **Card Types:**
  - **Grey Infrastructure:** e.g., Drainage upgrades, dike expansions.
  - **Green Infrastructure:** e.g., Rain gardens, bioswales, retention ponds.
- Each card has a resilience value (defense) and a cost.
- Cards can be purchased using your city's income.
- You can buy multiple cards per round if you can afford them.
- Built infrastructure increases your city's resilience, reducing future damage.

### Increasing Challenge
- Rain attacks become stronger as rounds progress, requiring you to continually upgrade your city's defenses.

## Modularity & Extensibility
- The game is designed for easy expansion:
  - The card pool is separated into its own file for easy modification and future card combinations or effects.
  - Game logic is organized into separate scripts for clarity and maintainability.

## How to Play
1. Start the game and review your city's status.
2. After each rain attack, choose which infrastructure cards to build.
3. Balance your spending to maximize resilience and income.
4. Survive as many rounds as possible!

---

*This project is open for contributions and ideas! Feel free to suggest new cards, mechanics, or improvements.* 