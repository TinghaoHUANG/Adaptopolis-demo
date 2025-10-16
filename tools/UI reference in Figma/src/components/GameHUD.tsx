import { Button } from './ui/button';
import { Heart, Coins, Shield, Cloud } from 'lucide-react';

interface GameHUDProps {
  round: number;
  health: number;
  maxHealth: number;
  money: number;
  resilience: number;
  rainForecast: { min: number; max: number };
  statusMessage: string;
  onNextRound: () => void;
  onRestart: () => void;
  canNextRound: boolean;
}

export default function GameHUD({
  round,
  health,
  maxHealth,
  money,
  resilience,
  rainForecast,
  statusMessage,
  onNextRound,
  onRestart,
  canNextRound,
}: GameHUDProps) {
  return (
    <div className="absolute left-4 top-36 w-72 space-y-3">
      {/* Stats Panel */}
      <div 
        className="bg-slate-900 border-4 border-purple-500 p-4 relative"
        style={{
          boxShadow: '0 0 20px rgba(168, 85, 247, 0.4), inset 0 2px 0 rgba(255,255,255,0.1)',
        }}
      >
        <div className="absolute -top-3 left-3 bg-purple-500 px-2 py-1 border-2 border-purple-700">
          <span className="text-white text-xs">STATS</span>
        </div>
        
        <div className="space-y-2 text-white text-xs mt-2">
          <div className="flex items-center justify-between">
            <span>ROUND</span>
            <span className="text-yellow-400">{round}</span>
          </div>
          <div className="h-px bg-purple-500/30" />
          
          <div className="flex items-center justify-between gap-2">
            <div className="flex items-center gap-2">
              <Heart className="w-3 h-3 fill-red-500 text-red-500" />
              <span>HEALTH</span>
            </div>
            <span className="text-red-400">{health}/{maxHealth}</span>
          </div>
          <div className="h-px bg-purple-500/30" />
          
          <div className="flex items-center justify-between gap-2">
            <div className="flex items-center gap-2">
              <Coins className="w-3 h-3 text-yellow-400" />
              <span>FUNDS</span>
            </div>
            <span className="text-yellow-400">{money}</span>
          </div>
          <div className="h-px bg-purple-500/30" />
          
          <div className="flex items-center justify-between gap-2">
            <div className="flex items-center gap-2">
              <Shield className="w-3 h-3 text-cyan-400" />
              <span>DEFENSE</span>
            </div>
            <span className="text-cyan-400">{resilience}</span>
          </div>
        </div>
      </div>

      {/* Rain Forecast Panel */}
      <div 
        className="bg-slate-900 border-4 border-blue-500 p-4 relative"
        style={{
          boxShadow: '0 0 20px rgba(59, 130, 246, 0.4), inset 0 2px 0 rgba(255,255,255,0.1)',
        }}
      >
        <div className="absolute -top-3 left-3 bg-blue-500 px-2 py-1 border-2 border-blue-700 flex items-center gap-1">
          <Cloud className="w-3 h-3 text-white" />
          <span className="text-white text-xs">FORECAST</span>
        </div>
        
        <div className="space-y-2 mt-2">
          <div className="text-blue-300 text-xs text-center">
            STORM DAMAGE
          </div>
          <div className="bg-blue-950 border-2 border-blue-700 p-2 text-center">
            <span className="text-yellow-400 text-sm">{rainForecast.min} - {rainForecast.max}</span>
          </div>
        </div>
      </div>

      {/* Next Round Button */}
      <Button
        onClick={onNextRound}
        disabled={!canNextRound}
        className="w-full bg-gradient-to-b from-green-500 to-green-700 hover:from-green-400 hover:to-green-600 text-white border-4 border-green-900 disabled:opacity-50 disabled:cursor-not-allowed relative overflow-hidden group py-6"
        style={{
          boxShadow: canNextRound ? '0 4px 0 #14532d, inset 0 -2px 0 rgba(0,0,0,0.3)' : 'none',
          textShadow: '2px 2px 0 rgba(0,0,0,0.5)'
        }}
      >
        <span className="text-xs tracking-wider">NEXT ROUND</span>
        {canNextRound && (
          <div className="absolute inset-0 bg-white opacity-0 group-hover:opacity-10 transition-opacity" />
        )}
      </Button>

      {/* Status Message */}
      <div 
        className="bg-slate-900 border-4 border-cyan-500 p-3"
        style={{
          boxShadow: '0 0 15px rgba(6, 182, 212, 0.3)',
        }}
      >
        <div className="text-cyan-300 text-xs leading-relaxed" style={{ lineHeight: '1.6' }}>
          {statusMessage}
        </div>
      </div>

      {/* Restart Button */}
      <Button
        onClick={onRestart}
        className="w-full bg-gradient-to-b from-red-600 to-red-800 hover:from-red-500 hover:to-red-700 text-white border-4 border-red-900 relative overflow-hidden group"
        style={{
          boxShadow: '0 4px 0 #7f1d1d, inset 0 -2px 0 rgba(0,0,0,0.3)',
          textShadow: '2px 2px 0 rgba(0,0,0,0.5)'
        }}
      >
        <span className="text-xs tracking-wider">RESTART</span>
        <div className="absolute inset-0 bg-white opacity-0 group-hover:opacity-10 transition-opacity" />
      </Button>
    </div>
  );
}
