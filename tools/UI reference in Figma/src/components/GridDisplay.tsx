import { GridCell } from '../App';
import { Building2, Droplet, Square } from 'lucide-react';

interface GridDisplayProps {
  cells: GridCell[];
  onCellClick: (id: number) => void;
  selectedCell: number | null;
}

export default function GridDisplay({ cells, onCellClick, selectedCell }: GridDisplayProps) {
  const getCellContent = (cell: GridCell) => {
    switch (cell.type) {
      case 'ground_1':
      case 'ground_2':
        return <Square className="w-10 h-10 text-amber-400 fill-amber-600/40" />;
      case 'building':
        return <Building2 className="w-10 h-10 text-slate-300 fill-slate-500/40" />;
      case 'water':
        return <Droplet className="w-10 h-10 text-cyan-400 fill-cyan-600/40" />;
      default:
        return null;
    }
  };

  const getCellStyle = (cell: GridCell) => {
    switch (cell.type) {
      case 'ground_1':
      case 'ground_2':
        return {
          background: 'linear-gradient(135deg, #78350f 0%, #92400e 50%, #78350f 100%)',
          borderColor: '#d97706',
          boxShadow: 'inset 0 2px 0 rgba(251, 191, 36, 0.2), 0 2px 0 rgba(0,0,0,0.3)'
        };
      case 'building':
        return {
          background: 'linear-gradient(135deg, #475569 0%, #64748b 50%, #475569 100%)',
          borderColor: '#94a3b8',
          boxShadow: 'inset 0 2px 0 rgba(148, 163, 184, 0.2), 0 2px 0 rgba(0,0,0,0.3)'
        };
      case 'water':
        return {
          background: 'linear-gradient(135deg, #0c4a6e 0%, #0369a1 50%, #0c4a6e 100%)',
          borderColor: '#0ea5e9',
          boxShadow: 'inset 0 2px 0 rgba(14, 165, 233, 0.2), 0 2px 0 rgba(0,0,0,0.3)'
        };
      default:
        return {
          background: 'linear-gradient(135deg, #1e293b 0%, #334155 50%, #1e293b 100%)',
          borderColor: '#475569',
          boxShadow: 'inset 0 2px 0 rgba(71, 85, 105, 0.2), 0 2px 0 rgba(0,0,0,0.3)'
        };
    }
  };

  return (
    <div className="absolute left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2">
      <div 
        className="p-6 bg-slate-900 border-8 border-slate-700 relative"
        style={{
          boxShadow: '0 0 40px rgba(0,0,0,0.5), inset 0 4px 0 rgba(255,255,255,0.1)',
        }}
      >
        {/* Decorative corners */}
        <div className="absolute -top-2 -left-2 w-4 h-4 bg-yellow-400 border-2 border-yellow-600" />
        <div className="absolute -top-2 -right-2 w-4 h-4 bg-yellow-400 border-2 border-yellow-600" />
        <div className="absolute -bottom-2 -left-2 w-4 h-4 bg-yellow-400 border-2 border-yellow-600" />
        <div className="absolute -bottom-2 -right-2 w-4 h-4 bg-yellow-400 border-2 border-yellow-600" />
        
        <div className="grid grid-cols-6 gap-2">
          {cells.map((cell) => {
            const cellStyle = getCellStyle(cell);
            const isSelected = selectedCell === cell.id;
            
            return (
              <button
                key={cell.id}
                onClick={() => onCellClick(cell.id)}
                className="w-20 h-20 border-4 transition-all flex items-center justify-center relative group"
                style={{
                  ...cellStyle,
                  borderColor: isSelected ? '#facc15' : cellStyle.borderColor,
                  transform: isSelected ? 'scale(0.95)' : 'scale(1)',
                }}
              >
                {getCellContent(cell)}
                
                {/* Hover effect */}
                <div className="absolute inset-0 bg-white opacity-0 group-hover:opacity-10 transition-opacity pointer-events-none" />
                
                {/* Selected indicator */}
                {isSelected && (
                  <>
                    <div className="absolute -top-1 -left-1 w-2 h-2 bg-yellow-400 animate-pulse" />
                    <div className="absolute -top-1 -right-1 w-2 h-2 bg-yellow-400 animate-pulse" />
                    <div className="absolute -bottom-1 -left-1 w-2 h-2 bg-yellow-400 animate-pulse" />
                    <div className="absolute -bottom-1 -right-1 w-2 h-2 bg-yellow-400 animate-pulse" />
                  </>
                )}
              </button>
            );
          })}
        </div>
      </div>
    </div>
  );
}
