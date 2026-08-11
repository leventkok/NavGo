type PromptChipsProps = {
  prompts: string[];
  disabled?: boolean;
  onSelect: (prompt: string) => void;
};

export default function PromptChips({ prompts, disabled, onSelect }: PromptChipsProps) {
  return (
    <div className="flex flex-wrap gap-2 px-1 pb-2">
      {prompts.map((prompt) => (
        <button
          key={prompt}
          type="button"
          disabled={disabled}
          onClick={() => onSelect(prompt)}
          className="rounded-full border border-outline-variant bg-surface-container-low px-3 py-1.5 text-left font-body-sm text-body-sm text-on-surface-variant transition-colors hover:border-primary hover:text-primary disabled:opacity-50"
        >
          {prompt}
        </button>
      ))}
    </div>
  );
}
