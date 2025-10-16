import { Button } from './ui/button';
import { Facility } from '../App';
import { Building2, Droplet, Square, ShoppingCart } from 'lucide-react';

interface ShopPanelProps {
  offers: Facility[];
  selectedItem: Facility | null;
  onPurchase: (facility: Facility) => void;
  onSkip: () => void;
  onRefresh: () => void;
  money: number;
}

export default function ShopPanel({
  offers,
  selectedItem,
  onPurchase,
  onSkip,
  onRefresh,
  money,
}: ShopPanelProps) {
  const getIcon = (type: string) => {
    switch (type) {
      case 'ground':
        return <Square className="w-5 h-5" />;
      case 'building':
        return <Building2 className="w-5 h-5" />;
      case 'water':
        return <Droplet className="w-5 h-5" />;
      default:
        return null;
    }
  };

  return (
    <div 
      className="absolute right-6 top-1/2 -translate-y-1/2 w-80 bg-slate-900 border-4 border-emerald-500 p-4"
      style={{
        boxShadow: '0 0 30px rgba(16, 185, 129, 0.4), inset 0 2px 0 rgba(255,255,255,0.1)',
      }}
    >
      <div className="space-y-4">
        {/* Header */}
        <div className="flex items-center justify-center gap-2 text-emerald-400 border-b-2 border-emerald-500/30 pb-2">
          <ShoppingCart className="w-4 h-4" />
          <span className="text-xs tracking-wider">SHOP</span>
        </div>

        {/* Offer List */}
        <div className="space-y-2 min-h-[200px]">
          {offers.map((offer) => {
            const canAfford = money >= offer.cost;
            const isSelected = selectedItem?.id === offer.id;
            
            return (
              <button
                key={offer.id}
                onClick={() => onPurchase(offer)}
                disabled={!canAfford}
                className="w-full p-3 text-left transition-all border-4 relative group"
                style={{
                  background: isSelected 
                    ? 'linear-gradient(135deg, #065f46 0%, #047857 100%)' 
                    : 'linear-gradient(135deg, #1e293b 0%, #334155 100%)',
                  borderColor: isSelected ? '#10b981' : canAfford ? '#475569' : '#1e293b',
                  boxShadow: isSelected 
                    ? '0 0 15px rgba(16, 185, 129, 0.5), inset 0 2px 0 rgba(255,255,255,0.1)' 
                    : 'inset 0 2px 0 rgba(71, 85, 105, 0.2)',
                  opacity: canAfford ? 1 : 0.5,
                  cursor: canAfford ? 'pointer' : 'not-allowed'
                }}
              >
                <div className="flex items-start gap-3">
                  <div className="text-white mt-1">{getIcon(offer.type)}</div>
                  <div className="flex-1 space-y-1">
                    <div className="text-white text-xs">{offer.name}</div>
                    <div className="text-slate-300 text-[10px] leading-relaxed" style={{ lineHeight: '1.5' }}>
                      {offer.description}
                    </div>
                    <div className="flex items-center gap-3 text-[10px] pt-1">
                      <span className="text-yellow-400">💰 {offer.cost}</span>
                      <span className="text-cyan-400">🛡️ +{offer.resilience}</span>
                    </div>
                  </div>
                </div>
                
                {/* Corner indicators for selected item */}
                {isSelected && (
                  <>
                    <div className="absolute -top-1 -left-1 w-2 h-2 bg-emerald-400" />
                    <div className="absolute -top-1 -right-1 w-2 h-2 bg-emerald-400" />
                    <div className="absolute -bottom-1 -left-1 w-2 h-2 bg-emerald-400" />
                    <div className="absolute -bottom-1 -right-1 w-2 h-2 bg-emerald-400" />
                  </>
                )}
                
                {canAfford && !isSelected && (
                  <div className="absolute inset-0 bg-white opacity-0 group-hover:opacity-10 transition-opacity" />
                )}
              </button>
            );
          })}
        </div>

        {/* Detail Label */}
        <div 
          className="bg-slate-800 border-2 border-slate-600 p-3 min-h-[80px]"
          style={{
            boxShadow: 'inset 0 2px 0 rgba(0,0,0,0.3)'
          }}
        >
          <div className="text-slate-300 text-[10px] leading-relaxed" style={{ lineHeight: '1.6' }}>
            {selectedItem 
              ? `Selected: ${selectedItem.name}. Click grid to place it.`
              : 'Select facility, then click grid to place it.'
            }
          </div>
        </div>

        {/* Controls */}
        <div className="flex gap-2">
          <Button
            onClick={onSkip}
            className="flex-1 bg-gradient-to-b from-slate-600 to-slate-800 hover:from-slate-500 hover:to-slate-700 text-white border-4 border-slate-900 relative overflow-hidden group"
            style={{
              boxShadow: '0 4px 0 #0f172a, inset 0 -2px 0 rgba(0,0,0,0.3)',
              textShadow: '1px 1px 0 rgba(0,0,0,0.5)'
            }}
          >
            <span className="text-xs">SKIP</span>
            <div className="absolute inset-0 bg-white opacity-0 group-hover:opacity-10 transition-opacity" />
          </Button>
          
          <Button
            onClick={onRefresh}
            className="flex-1 bg-gradient-to-b from-blue-600 to-blue-800 hover:from-blue-500 hover:to-blue-700 text-white border-4 border-blue-900 relative overflow-hidden group"
            style={{
              boxShadow: '0 4px 0 #1e3a8a, inset 0 -2px 0 rgba(0,0,0,0.3)',
              textShadow: '1px 1px 0 rgba(0,0,0,0.5)'
            }}
          >
            <span className="text-xs">REFRESH (5)</span>
            <div className="absolute inset-0 bg-white opacity-0 group-hover:opacity-10 transition-opacity" />
          </Button>
        </div>
      </div>
    </div>
  );
}
