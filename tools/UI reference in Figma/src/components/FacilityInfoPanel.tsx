import { Facility } from '../App';
import { Button } from './ui/button';
import { Building2, Droplet, Square, X } from 'lucide-react';

interface FacilityInfoPanelProps {
  facility: Facility;
  onSell: () => void;
  onClose: () => void;
}

export default function FacilityInfoPanel({ facility, onSell, onClose }: FacilityInfoPanelProps) {
  const getIcon = (type: string) => {
    switch (type) {
      case 'ground':
        return <Square className="w-6 h-6 text-amber-400" />;
      case 'building':
        return <Building2 className="w-6 h-6 text-slate-300" />;
      case 'water':
        return <Droplet className="w-6 h-6 text-cyan-400" />;
      default:
        return null;
    }
  };

  return (
    <div 
      className="absolute left-[340px] top-[140px] w-[260px] bg-slate-900 border-4 border-orange-500 p-4"
      style={{
        boxShadow: '0 0 30px rgba(249, 115, 22, 0.4), inset 0 2px 0 rgba(255,255,255,0.1)',
      }}
    >
      <button
        onClick={onClose}
        className="absolute -top-3 -right-3 w-6 h-6 bg-red-600 border-2 border-red-800 flex items-center justify-center hover:bg-red-500 transition-colors"
        style={{
          boxShadow: '0 2px 0 #7f1d1d'
        }}
      >
        <X className="w-4 h-4 text-white" />
      </button>
      
      <div className="space-y-4">
        <div className="flex items-center justify-center gap-2 text-orange-400 border-b-2 border-orange-500/30 pb-2">
          {getIcon(facility.type)}
          <span className="text-xs tracking-wider">{facility.name.toUpperCase()}</span>
        </div>
        
        <div 
          className="bg-slate-800 border-2 border-orange-700 p-3 min-h-[100px]"
          style={{
            boxShadow: 'inset 0 2px 0 rgba(0,0,0,0.3)'
          }}
        >
          <div className="space-y-3 text-[10px]">
            <p className="text-slate-300 leading-relaxed" style={{ lineHeight: '1.6' }}>
              {facility.description}
            </p>
            
            <div className="space-y-1 border-t-2 border-slate-700 pt-2">
              <div className="flex justify-between text-slate-300">
                <span>COST:</span>
                <span className="text-yellow-400">💰 {facility.cost}</span>
              </div>
              <div className="flex justify-between text-slate-300">
                <span>DEFENSE:</span>
                <span className="text-cyan-400">🛡️ +{facility.resilience}</span>
              </div>
              <div className="flex justify-between text-slate-300">
                <span>SELL VALUE:</span>
                <span className="text-emerald-400">💰 {Math.floor(facility.cost * 0.7)}</span>
              </div>
            </div>
          </div>
        </div>
        
        <Button
          onClick={onSell}
          className="w-full bg-gradient-to-b from-red-600 to-red-800 hover:from-red-500 hover:to-red-700 text-white border-4 border-red-900 relative overflow-hidden group"
          style={{
            boxShadow: '0 4px 0 #7f1d1d, inset 0 -2px 0 rgba(0,0,0,0.3)',
            textShadow: '1px 1px 0 rgba(0,0,0,0.5)'
          }}
        >
          <span className="text-xs tracking-wider">SELL</span>
          <div className="absolute inset-0 bg-white opacity-0 group-hover:opacity-10 transition-opacity" />
        </Button>
      </div>
      
      {/* Decorative corners */}
      <div className="absolute -top-2 -left-2 w-3 h-3 bg-orange-400 border-2 border-orange-600" />
      <div className="absolute -bottom-2 -left-2 w-3 h-3 bg-orange-400 border-2 border-orange-600" />
      <div className="absolute -bottom-2 -right-2 w-3 h-3 bg-orange-400 border-2 border-orange-600" />
    </div>
  );
}
