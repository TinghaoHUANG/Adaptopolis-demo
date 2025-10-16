import { Button } from './ui/button';
import { Trophy, Star } from 'lucide-react';

interface VictoryMenuProps {
  onRestart: () => void;
  onContinueEndless: () => void;
}

export default function VictoryMenu({ onRestart, onContinueEndless }: VictoryMenuProps) {
  return (
    <div className="absolute inset-0 z-[60] flex items-center justify-center">
      {/* Background overlay with pixel pattern */}
      <div 
        className="absolute inset-0" 
        style={{
          backgroundImage: `
            repeating-linear-gradient(0deg, rgba(255,255,255,0.03) 0px, transparent 1px, transparent 4px, rgba(255,255,255,0.03) 5px),
            repeating-linear-gradient(90deg, rgba(255,255,255,0.03) 0px, transparent 1px, transparent 4px, rgba(255,255,255,0.03) 5px)
          `,
          backgroundColor: 'rgba(0, 0, 0, 0.8)'
        }}
      />
      
      {/* Menu content */}
      <div className="relative z-10">
        <div 
          className="w-[400px] min-h-[280px] bg-slate-900 border-8 border-yellow-500 p-8 relative"
          style={{
            boxShadow: '0 0 60px rgba(234, 179, 8, 0.6), inset 0 4px 0 rgba(255,255,255,0.1)',
          }}
        >
          {/* Decorative stars */}
          <Star className="absolute -top-4 -left-4 w-8 h-8 text-yellow-400 fill-yellow-400 animate-pulse" />
          <Star className="absolute -top-4 -right-4 w-8 h-8 text-yellow-400 fill-yellow-400 animate-pulse" />
          
          <div className="space-y-6">
            <div className="space-y-4 text-center">
              <div className="flex justify-center">
                <Trophy className="w-16 h-16 text-yellow-400 fill-yellow-400/20" />
              </div>
              
              <h2 className="text-3xl text-yellow-400 pixel-text-shadow" style={{ lineHeight: '1.4' }}>
                VICTORY!
              </h2>
              
              <div 
                className="w-full h-1 bg-gradient-to-r from-transparent via-yellow-400 to-transparent"
                style={{ imageRendering: 'pixelated' }}
              />
              
              <p className="text-cyan-300 text-xs leading-relaxed" style={{ lineHeight: '1.8' }}>
                City secured!<br/>Choose how to proceed.
              </p>
            </div>
            
            <div className="flex flex-col gap-3">
              <Button
                onClick={onContinueEndless}
                className="w-full bg-gradient-to-b from-emerald-500 to-emerald-700 hover:from-emerald-400 hover:to-emerald-600 text-white border-4 border-emerald-900 relative overflow-hidden group py-6"
                style={{
                  boxShadow: '0 6px 0 #064e3b, inset 0 -2px 0 rgba(0,0,0,0.3)',
                  textShadow: '2px 2px 0 rgba(0,0,0,0.5)'
                }}
              >
                <span className="text-xs tracking-wider">CONTINUE ENDLESS</span>
                <div className="absolute inset-0 bg-white opacity-0 group-hover:opacity-10 transition-opacity" />
              </Button>
              
              <Button
                onClick={onRestart}
                className="w-full bg-gradient-to-b from-slate-600 to-slate-800 hover:from-slate-500 hover:to-slate-700 text-white border-4 border-slate-900 relative overflow-hidden group"
                style={{
                  boxShadow: '0 4px 0 #0f172a, inset 0 -2px 0 rgba(0,0,0,0.3)',
                  textShadow: '1px 1px 0 rgba(0,0,0,0.5)'
                }}
              >
                <span className="text-xs tracking-wider">RESTART</span>
                <div className="absolute inset-0 bg-white opacity-0 group-hover:opacity-10 transition-opacity" />
              </Button>
            </div>
          </div>
          
          {/* Decorative corners */}
          <div className="absolute -top-3 -left-3 w-5 h-5 bg-yellow-400 border-2 border-yellow-600" />
          <div className="absolute -top-3 -right-3 w-5 h-5 bg-yellow-400 border-2 border-yellow-600" />
          <div className="absolute -bottom-3 -left-3 w-5 h-5 bg-yellow-400 border-2 border-yellow-600" />
          <div className="absolute -bottom-3 -right-3 w-5 h-5 bg-yellow-400 border-2 border-yellow-600" />
        </div>
      </div>
    </div>
  );
}
