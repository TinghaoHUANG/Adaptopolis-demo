import { useState, useEffect } from 'react';
import StartMenu from './components/StartMenu';
import GameHUD from './components/GameHUD';
import GridDisplay from './components/GridDisplay';
import ShopPanel from './components/ShopPanel';
import CardBar from './components/CardBar';
import CardInfoPanel from './components/CardInfoPanel';
import FacilityInfoPanel from './components/FacilityInfoPanel';
import VictoryMenu from './components/VictoryMenu';

export interface Facility {
  id: string;
  name: string;
  type: 'ground' | 'building' | 'water';
  cost: number;
  resilience: number;
  description: string;
}

export interface Card {
  id: string;
  name: string;
  description: string;
  unlocked: boolean;
}

export interface GridCell {
  id: number;
  type: 'empty' | 'ground_1' | 'ground_2' | 'building' | 'water';
  facility?: Facility;
}

export default function App() {
  const [gameState, setGameState] = useState<'start' | 'playing' | 'shop' | 'victory'>('start');
  const [round, setRound] = useState(1);
  const [health, setHealth] = useState(20);
  const [maxHealth] = useState(20);
  const [money, setMoney] = useState(30);
  const [resilience, setResilience] = useState(0);
  const [rainForecast, setRainForecast] = useState({ min: 5, max: 15 });
  const [statusMessage, setStatusMessage] = useState('Welcome to Adaptopolis!');
  const [endlessMode, setEndlessMode] = useState(false);
  
  const [gridCells, setGridCells] = useState<GridCell[]>([]);
  const [selectedShopItem, setSelectedShopItem] = useState<Facility | null>(null);
  const [selectedGridCell, setSelectedGridCell] = useState<number | null>(null);
  const [cards, setCards] = useState<Card[]>([
    { id: '1', name: 'Rain Shield', description: '+2 Resilience against floods', unlocked: false },
    { id: '2', name: 'Foundation', description: 'Strengthens buildings by 3', unlocked: false },
    { id: '3', name: 'Water Tank', description: 'Stores excess water', unlocked: false },
  ]);
  const [hoveredCard, setHoveredCard] = useState<Card | null>(null);
  
  const [shopOffers, setShopOffers] = useState<Facility[]>([]);

  // Initialize grid
  useEffect(() => {
    const initialGrid: GridCell[] = [];
    for (let i = 0; i < 36; i++) {
      initialGrid.push({
        id: i,
        type: 'empty',
      });
    }
    setGridCells(initialGrid);
  }, []);

  const startGame = () => {
    setGameState('playing');
    setStatusMessage('Build your city infrastructure!');
    generateShopOffers();
  };

  const generateShopOffers = () => {
    const facilities: Facility[] = [
      { id: '1', name: 'Ground Foundation', type: 'ground', cost: 10, resilience: 1, description: 'Basic ground tile. +1 Resilience.' },
      { id: '2', name: 'Reinforced Ground', type: 'ground', cost: 15, resilience: 2, description: 'Strong ground tile. +2 Resilience.' },
      { id: '3', name: 'Residential Building', type: 'building', cost: 25, resilience: 3, description: 'Houses citizens. +3 Resilience.' },
      { id: '4', name: 'Water Management', type: 'water', cost: 20, resilience: 2, description: 'Controls flooding. +2 Resilience.' },
      { id: '5', name: 'Storm Shelter', type: 'building', cost: 35, resilience: 5, description: 'Emergency shelter. +5 Resilience.' },
    ];
    
    // Random 3 offers
    const shuffled = facilities.sort(() => 0.5 - Math.random());
    setShopOffers(shuffled.slice(0, 3));
    setGameState('shop');
  };

  const handlePurchase = (facility: Facility) => {
    if (money >= facility.cost) {
      setSelectedShopItem(facility);
      setStatusMessage(`Selected ${facility.name}. Click a grid cell to place it.`);
    } else {
      setStatusMessage('Not enough funds!');
    }
  };

  const handleGridCellClick = (cellId: number) => {
    if (selectedShopItem && gameState === 'shop') {
      if (money >= selectedShopItem.cost) {
        setGridCells(prev => prev.map(cell => 
          cell.id === cellId 
            ? { ...cell, type: selectedShopItem.type as any, facility: selectedShopItem }
            : cell
        ));
        setMoney(prev => prev - selectedShopItem.cost);
        setResilience(prev => prev + selectedShopItem.resilience);
        setStatusMessage(`Placed ${selectedShopItem.name}!`);
        setSelectedShopItem(null);
      }
    } else {
      setSelectedGridCell(cellId);
    }
  };

  const handleSkipShop = () => {
    setGameState('playing');
    setStatusMessage('Shop skipped. Prepare for the next round!');
  };

  const handleRefreshShop = () => {
    const refreshCost = 5;
    if (money >= refreshCost) {
      setMoney(prev => prev - refreshCost);
      generateShopOffers();
      setStatusMessage('Shop refreshed!');
    } else {
      setStatusMessage('Not enough funds to refresh!');
    }
  };

  const handleNextRound = () => {
    if (gameState !== 'playing') return;
    
    const nextRound = round + 1;
    setRound(nextRound);
    
    // Calculate rain damage
    const rainDamage = Math.floor(Math.random() * (rainForecast.max - rainForecast.min + 1)) + rainForecast.min;
    const actualDamage = Math.max(0, rainDamage - resilience);
    
    setHealth(prev => {
      const newHealth = Math.max(0, prev - actualDamage);
      if (newHealth <= 0) {
        setStatusMessage('City destroyed! Click Restart to try again.');
        return 0;
      }
      return newHealth;
    });
    
    if (actualDamage > 0) {
      setStatusMessage(`Storm caused ${actualDamage} damage! Health: ${health - actualDamage}`);
    } else {
      setStatusMessage(`Your resilience protected the city!`);
    }
    
    setMoney(prev => prev + 20);
    setRainForecast({ min: Math.floor(Math.random() * 10) + 3, max: Math.floor(Math.random() * 15) + 10 });
    
    // Unlock cards
    if (nextRound === 5 && !cards[0].unlocked) {
      setCards(prev => prev.map((c, i) => i === 0 ? { ...c, unlocked: true } : c));
    }
    
    // Check victory
    if (nextRound > 20 && !endlessMode) {
      setGameState('victory');
      return;
    }
    
    generateShopOffers();
  };

  const handleRestart = () => {
    setGameState('start');
    setRound(1);
    setHealth(20);
    setMoney(30);
    setResilience(0);
    setStatusMessage('Welcome to Adaptopolis!');
    setEndlessMode(false);
    setSelectedShopItem(null);
    setSelectedGridCell(null);
    setGridCells(prev => prev.map(cell => ({ ...cell, type: 'empty', facility: undefined })));
  };

  const handleSellFacility = () => {
    if (selectedGridCell !== null) {
      const cell = gridCells[selectedGridCell];
      if (cell.facility) {
        const refund = Math.floor(cell.facility.cost * 0.7);
        setMoney(prev => prev + refund);
        setResilience(prev => prev - cell.facility!.resilience);
        setGridCells(prev => prev.map(c => 
          c.id === selectedGridCell 
            ? { ...c, type: 'empty', facility: undefined }
            : c
        ));
        setStatusMessage(`Sold ${cell.facility.name} for ${refund} funds.`);
        setSelectedGridCell(null);
      }
    }
  };

  const handleContinueEndless = () => {
    setEndlessMode(true);
    setGameState('playing');
    generateShopOffers();
  };

  return (
    <div className="relative w-screen h-screen overflow-hidden" style={{
      background: 'linear-gradient(135deg, #1a1a2e 0%, #16213e 50%, #0f3460 100%)'
    }}>
      {gameState === 'start' && (
        <StartMenu onStart={startGame} />
      )}
      
      {gameState === 'victory' && (
        <VictoryMenu 
          onRestart={handleRestart}
          onContinueEndless={handleContinueEndless}
        />
      )}

      {(gameState === 'playing' || gameState === 'shop') && (
        <>
          <CardBar 
            cards={cards}
            onCardHover={setHoveredCard}
          />
          
          {hoveredCard && (
            <CardInfoPanel card={hoveredCard} />
          )}

          <GameHUD
            round={round}
            health={health}
            maxHealth={maxHealth}
            money={money}
            resilience={resilience}
            rainForecast={rainForecast}
            statusMessage={statusMessage}
            onNextRound={handleNextRound}
            onRestart={handleRestart}
            canNextRound={gameState === 'playing'}
          />

          <GridDisplay
            cells={gridCells}
            onCellClick={handleGridCellClick}
            selectedCell={selectedGridCell}
          />

          {gameState === 'shop' && (
            <ShopPanel
              offers={shopOffers}
              selectedItem={selectedShopItem}
              onPurchase={handlePurchase}
              onSkip={handleSkipShop}
              onRefresh={handleRefreshShop}
              money={money}
            />
          )}

          {selectedGridCell !== null && gridCells[selectedGridCell]?.facility && (
            <FacilityInfoPanel
              facility={gridCells[selectedGridCell].facility!}
              onSell={handleSellFacility}
              onClose={() => setSelectedGridCell(null)}
            />
          )}
        </>
      )}
    </div>
  );
}
