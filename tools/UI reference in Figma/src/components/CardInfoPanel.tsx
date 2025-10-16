import { Card as CardType } from '../App';
import { Sparkles } from 'lucide-react';

interface CardInfoPanelProps {
  card: CardType;
}

export default function CardInfoPanel({ card }: CardInfoPanelProps) {
  return (
    <div 
      className="absolute right-4 top-36 w-[320px] bg-slate-900 border-4 border-pink-500 p-4 z-50"
      style={{
        boxShadow: '0 0 30px rgba(236, 72, 153, 0.5), inset 0 2px 0 rgba(255,255,255,0.1)',
      }}
    >
      <div className="space-y-4">
        <div className="flex items-center justify-center gap-2 text-pink-400 border-b-2 border-pink-500/30 pb-2">
          <Sparkles className="w-4 h-4" />
          <span className="text-xs tracking-wider">{card.name}</span>
        </div>
        
        <div 
          className="bg-slate-800 border-2 border-pink-700 p-4 min-h-[80px]"
          style={{
            boxShadow: 'inset 0 2px 0 rgba(0,0,0,0.3)'
          }}
        >
          <div className="text-pink-200 text-[11px] leading-relaxed" style={{ lineHeight: '1.7' }}>
            {card.description}
          </div>
        </div>
      </div>
      
      {/* Decorative corners */}
      <div className="absolute -top-2 -left-2 w-3 h-3 bg-pink-400 border-2 border-pink-600" />
      <div className="absolute -top-2 -right-2 w-3 h-3 bg-pink-400 border-2 border-pink-600" />
      <div className="absolute -bottom-2 -left-2 w-3 h-3 bg-pink-400 border-2 border-pink-600" />
      <div className="absolute -bottom-2 -right-2 w-3 h-3 bg-pink-400 border-2 border-pink-600" />
    </div>
  );
}
