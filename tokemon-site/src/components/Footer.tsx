export function Footer() {
  return (
    <footer className="border-t border-border py-10">
      <div className="max-w-[1080px] mx-auto px-6 flex flex-col sm:flex-row justify-between items-center gap-4">
        <div className="text-[13px] text-secondary-text">Tokemon — macOS 14+ &middot; Free &amp; open source</div>
        <div className="flex gap-6 text-[13px]">
          <a href="https://github.com/richyparr/tokemon" className="text-secondary-text hover:text-[#ededed] transition-colors">GitHub</a>
          <a href="https://github.com/richyparr/tokemon/releases/latest" className="text-secondary-text hover:text-[#ededed] transition-colors">Releases</a>
          <a href="https://github.com/richyparr/tokemon/issues" className="text-secondary-text hover:text-[#ededed] transition-colors">Issues</a>
        </div>
      </div>
    </footer>
  );
}
