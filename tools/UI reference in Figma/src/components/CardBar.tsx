import { Card as CardType } from '../App';
import { Sparkles } from 'lucide-react';

interface CardBarProps {
  cards: CardType[];
  onCardHover: (card: CardType | null) => void;
}

export default function CardBar({ cards, onCardHover }: CardBarProps) {
  const unlockedCards = cards.filter(c => c.unlocked);

  return (
    <div 
      className="absolute left-4 right-4 top-2 bg-slate-900 border-4 border-pink-500 p-4"
      style={{
        boxShadow: '0 0 30px rgba(236, 72, 153, 0.4), inset 0 2px 0 rgba(255,255,255,0.1)',
      }}
    >
      <div className="space-y-3">
        <div className="flex items-center justify-center gap-2 text-pink-400 border-b-2 border-pink-500/30 pb-2">
          <Sparkles className="w-4 h-4" />
          <span className="text-xs tracking-wider">CARD BAR</span>
        </div>
        
        {unlockedCards.length === 0 ? (
          <div className="text-slate-400 text-center text-xs py-4">NO CARDS UNLOCKED</div>
        ) : (
          <div className="flex gap-3 justify-center flex-wrap">
            {unlockedCards.map((card) => (
              <button
                key={card.id}
                onMouseEnter={() => onCardHover(card)}
                onMouseLeave={() => onCardHover(null)}
                className="px-4 py-3 border-4 transition-all relative group"
                style={{
                  background: 'linear-gradient(135deg, #831843 0%, #be185d 50%, #831843 100%)',
                  borderColor: '#ec4899',
                  boxShadow: '0 4px 0 #701a75, inset 0 2px 0 rgba(255,255,255,0.2)',
                  textShadow: '1px 1px 0 rgba(0,0,0,0.5)'
                }}
              >
                <span className="text-white text-xs tracking-wide">{card.name}</span>
                
                {/* Hover glow */}
                <div className="absolute inset-0 bg-white opacity-0 group-hover:opacity-20 transition-opacity" />
                
                {/* Corner decorations */}
                <div className="absolute -top-1 -left-1 w-2 h-2 bg-pink-400" />
                <div className="absolute -top-1 -right-1 w-2 h-2 bg-pink-400" />
                <div className="absolute -bottom-1 -left-1 w-2 h-2 bg-pink-400" />
                <div className="absolute -bottom-1 -right-1 w-2 h-2 bg-pink-400" />
              </button>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
