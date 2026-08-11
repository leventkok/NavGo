type ModelStatusProps = {
  loaded: boolean;
  loading: boolean;
  modelId?: string | null;
};

export default function ModelStatus({ loaded, loading, modelId }: ModelStatusProps) {
  if (loading) {
    return (
      <span className="flex items-center gap-1.5 font-body-sm text-body-sm text-tertiary">
        <span className="h-2 w-2 animate-pulse rounded-full bg-tertiary" />
        İndiriliyor…
      </span>
    );
  }
  if (loaded) {
    return (
      <span className="flex items-center gap-1.5 font-body-sm text-body-sm text-primary">
        <span className="h-2 w-2 rounded-full bg-primary" />
        {modelId ? modelId.replace("-MLC", "") : "Gemma hazır"}
      </span>
    );
  }
  return (
    <span className="flex items-center gap-1.5 font-body-sm text-body-sm text-on-surface-variant">
      <span className="h-2 w-2 rounded-full bg-outline-variant" />
      Model yüklü değil
    </span>
  );
}
