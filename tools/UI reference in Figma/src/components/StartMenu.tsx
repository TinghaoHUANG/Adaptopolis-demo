import { Button } from './ui/button';

interface StartMenuProps {
  onStart: () => void;
}

export default function StartMenu({ onStart }: StartMenuProps) {
  return (
    <div className="absolute inset-0 z-50 flex items-center justify-center">
      {/* Pixel pattern background */}
      <div 
        className="absolute inset-0" 
        style={{
          backgroundImage: `
            repeating-linear-gradient(0deg, rgba(255,255,255,0.03) 0px, transparent 1px, transparent 4px, rgba(255,255,255,0.03) 5px),
            repeating-linear-gradient(90deg, rgba(255,255,255,0.03) 0px, transparent 1px, transparent 4px, rgba(255,255,255,0.03) 5px)
          `,
          backgroundColor: 'rgba(0, 0, 0, 0.7)'
        }}
      />
      
      {/* Menu content */}
      <div className="relative z-10 flex flex-col items-center justify-center gap-8 p-8">
        <div className="text-center space-y-6">
          <h1 className="text-5xl text-yellow-400 pixel-text-shadow" style={{ lineHeight: '1.3' }}>
            ADAPTOPOLIS
          </h1>
          <div 
            className="w-full h-1 bg-gradient-to-r from-transparent via-yellow-400 to-transparent"
            style={{ imageRendering: 'pixelated' }}
          />
          <p className="text-white text-xs leading-relaxed max-w-[400px]" style={{ lineHeight: '1.8' }}>
            Build resilient infrastructure<br/>before the storms arrive
          </p>
        </div>
        
        <div 
          className="relative p-1 bg-gradient-to-br from-yellow-400 to-orange-500"
          style={{
            clipPath: 'polygon(0 0, 100% 0, 100% calc(100% - 8px), calc(100% - 8px) 100%, 0 100%)'
          }}
        >
          <div 
            className="bg-slate-900 p-8"
            style={{
              clipPath: 'polygon(0 0, 100% 0, 100% calc(100% - 8px), calc(100% - 8px) 100%, 0 100%)'
            }}
          >
            <Button 
              onClick={onStart}
              className="px-8 py-6 bg-gradient-to-b from-emerald-500 to-emerald-700 hover:from-emerald-400 hover:to-emerald-600 text-white border-4 border-emerald-900 relative overflow-hidden group"
              style={{
                boxShadow: '0 4px 0 #064e3b, inset 0 -2px 0 rgba(0,0,0,0.3)',
                textShadow: '2px 2px 0 rgba(0,0,0,0.5)'
              }}
            >
              <span className="relative z-10 text-sm tracking-wider">START GAME</span>
              <div className="absolute inset-0 bg-white opacity-0 group-hover:opacity-10 transition-opacity" />
            </Button>
          </div>
        </div>
        
        <div 
          className="bg-slate-900/80 border-4 border-cyan-500 px-6 py-3"
          style={{
            boxShadow: '0 0 20px rgba(6, 182, 212, 0.3)',
          }}
        >
          <p className="text-cyan-300 text-center text-xs leading-relaxed" style={{ lineHeight: '1.8' }}>
            Survive 20 rounds<br/>to secure the city
          </p>
        </div>
      </div>
    </div>
  );
}
