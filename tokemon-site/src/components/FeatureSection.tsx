import Image from "next/image";

interface FeatureSectionProps {
  problem: string;
  title: string;
  description: string;
  solution: string;
  useCase: { bold: string; text: string };
  image: string;
  imageAlt: string;
  reverse?: boolean;
}

export function FeatureSection({ problem, title, description, solution, useCase, image, imageAlt, reverse }: FeatureSectionProps) {
  return (
    <section className="py-30">
      <div className="max-w-[1080px] mx-auto px-6">
        <div className={`grid grid-cols-1 md:grid-cols-2 gap-16 items-center ${reverse ? "md:[direction:rtl]" : ""}`}>
          <div className={reverse ? "md:[direction:ltr]" : ""}>
            <div className="inline-block text-xs font-semibold uppercase tracking-[0.08em] text-accent mb-4">{problem}</div>
            <h2 className="text-2xl md:text-[clamp(28px,4vw,44px)] font-bold tracking-tight mb-4 leading-tight">{title}</h2>
            <p className="text-base text-secondary-text leading-relaxed">{description}</p>
            <p className="text-base text-secondary-text leading-relaxed mt-3">{solution}</p>
            <div className="mt-5 p-4 px-5 bg-card border border-border rounded-[10px] text-sm text-secondary-text leading-relaxed">
              <strong className="text-[#ededed]">{useCase.bold}</strong>{useCase.text}
            </div>
          </div>
          <div className={`flex justify-center ${reverse ? "md:[direction:ltr]" : ""}`}>
            <Image
              src={image}
              alt={imageAlt}
              width={520}
              height={400}
              className="rounded-[10px] border border-border-light shadow-[0_16px_48px_rgba(0,0,0,0.5)] max-w-full h-auto"
            />
          </div>
        </div>
      </div>
    </section>
  );
}
