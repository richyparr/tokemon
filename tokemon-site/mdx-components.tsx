import type { MDXComponents } from "mdx/types";

export function useMDXComponents(): MDXComponents {
  return {
    // Comparison/blog tables are wider than a phone viewport; the body has
    // overflow-x-hidden, so without this wrapper they clip instead of scroll.
    table: (props) => (
      <div className="overflow-x-auto">
        <table {...props} />
      </div>
    ),
  };
}
