import type { Metadata } from "next";
import Link from "next/link";
import Image from "next/image";

const URL = "https://tokemon.ai/keychain-access";

export const metadata: Metadata = {
  title: "Authorize Tokemon in Keychain Access — Recovery Guide",
  description:
    "Step-by-step guide to add Tokemon to the Access Control list on the 'Claude Code-credentials' keychain item. Fixes the 'waiting for data' state when Claude Code rewrites credentials on /login.",
  alternates: { canonical: URL },
  robots: { index: false, follow: true },
};

const cx = "max-w-[820px] mx-auto px-6";

export default function KeychainAccessHelpPage() {
  return (
    <>
      <nav
        className="fixed top-0 left-0 right-0 z-50 border-b border-[#1a1a1a]"
        style={{ backdropFilter: "blur(20px)", WebkitBackdropFilter: "blur(20px)", background: "rgba(0,0,0,0.8)" }}
      >
        <div className="max-w-[1080px] mx-auto px-6 flex justify-between items-center h-14">
          <Link href="/" className="flex items-center gap-2.5 text-base font-semibold">
            <Image src="/icon.png" alt="Tokemon" width={24} height={24} className="rounded-[5px]" />
            tokemon
          </Link>
          <div className="flex items-center gap-8 text-sm">
            <Link href="/blog" className="text-[#777] hover:text-[#ededed] transition-colors hidden sm:inline">Blog</Link>
            <a href="https://github.com/richyparr/tokemon" className="text-[#777] hover:text-[#ededed] transition-colors hidden sm:inline">GitHub</a>
          </div>
        </div>
      </nav>

      <article className={`${cx} pt-32 pb-24`}>
        <div className="inline-block text-xs font-semibold uppercase tracking-[0.08em] text-[#f0a060] mb-4">
          Recovery guide
        </div>
        <h1 className="text-[clamp(32px,4.8vw,52px)] font-bold leading-[1.1] tracking-[-0.02em] mb-5">
          Authorize Tokemon in Keychain Access
        </h1>
        <p className="text-lg text-[#aaa] leading-relaxed mb-10">
          If Tokemon shows <strong className="text-[#ededed]">&quot;Tokemon needs Keychain access&quot;</strong>, it&apos;s because Claude Code recreated the credentials entry on <code className="font-mono text-[#f0a060]">/login</code> and reset the access control list. Adding Tokemon back takes about 30 seconds.
        </p>

        <div className="bg-[#0a0a0a] border border-[#f0a060]/30 rounded-xl p-5 mb-10">
          <p className="text-sm text-[#aaa] leading-relaxed">
            <strong className="text-[#ededed]">Why does this happen?</strong> macOS keychain items have an Access Control list — only apps on that list can read them without prompting. When Claude Code recreates the <code className="font-mono text-[#f0a060]">Claude Code-credentials</code> entry, only Claude Code itself is on the new list. Tokemon needs to be added back. This is a one-time setup that only repeats if Claude Code rewrites the entry again.
          </p>
        </div>

        <h2 className="text-2xl font-bold tracking-tight mb-6">Step-by-step</h2>

        <ol className="space-y-5">
          {[
            ["Open Keychain Access", "If it isn't already open, press Cmd+Space and type 'Keychain Access'. The Tokemon banner's 'Show Me How' button does this for you automatically."],
            ["Select the login keychain", "In the left sidebar under Default Keychains, click 'login'. (Items live in the login keychain — the iCloud one will be empty.)"],
            ["Search for the entry", "In the search box at the top right, paste 'Claude Code-credentials'. Tokemon copies this to your clipboard automatically."],
            ["Open Get Info", "Right-click the entry that appears and choose 'Get Info'. (Or select it and press Cmd+I.)"],
            ["Open the Access Control tab", "In the info window, click the 'Access Control' tab — usually the rightmost or second-to-last tab."],
            ["Add Tokemon", "Click the + button below the access list. In the file picker, press Cmd+Shift+G and paste /Applications/Tokemon.app, press Return, then click Add."],
            ["Save changes", "Click 'Save Changes'. Enter your macOS login password if prompted."],
            ["Return to Tokemon", "Click the Tokemon menu bar icon and hit 'Retry' — usage data should populate within a second."],
          ].map(([title, body], i) => (
            <li key={title} className="flex gap-4 bg-[#0a0a0a] border border-[#1a1a1a] rounded-xl p-5">
              <div className="flex-shrink-0 w-8 h-8 rounded-full bg-gradient-to-br from-[#f0a060] to-[#e88838] text-black font-bold flex items-center justify-center text-sm">
                {i + 1}
              </div>
              <div className="flex-1 min-w-0">
                <h3 className="text-[15px] font-semibold mb-2">{title}</h3>
                <p className="text-sm text-[#aaa] leading-relaxed">{body}</p>
              </div>
            </li>
          ))}
        </ol>

        <h2 className="text-2xl font-bold tracking-tight mt-14 mb-4">Troubleshooting</h2>

        <div className="space-y-4">
          <details className="group bg-[#0a0a0a] border border-[#1a1a1a] rounded-xl px-5 py-4 [&_summary::-webkit-details-marker]:hidden">
            <summary className="cursor-pointer flex justify-between items-center gap-4">
              <span className="font-semibold text-[15px]">Search returns no results</span>
              <span className="text-[#666] group-open:rotate-45 transition-transform">+</span>
            </summary>
            <p className="mt-3 text-sm text-[#aaa] leading-relaxed">
              You&apos;re probably looking at the iCloud keychain. Click <strong className="text-[#ededed]">login</strong> in the left sidebar and try again. If it&apos;s still empty, run <code className="font-mono text-[#f0a060]">claude /login</code> in your terminal — Claude Code creates the entry the first time you authenticate.
            </p>
          </details>
          <details className="group bg-[#0a0a0a] border border-[#1a1a1a] rounded-xl px-5 py-4 [&_summary::-webkit-details-marker]:hidden">
            <summary className="cursor-pointer flex justify-between items-center gap-4">
              <span className="font-semibold text-[15px]">macOS keeps prompting after I click Save</span>
              <span className="text-[#666] group-open:rotate-45 transition-transform">+</span>
            </summary>
            <p className="mt-3 text-sm text-[#aaa] leading-relaxed">
              That&apos;s your login password — not a yes/no prompt. Type your Mac account password and click Allow. macOS only asks once per Get Info session.
            </p>
          </details>
          <details className="group bg-[#0a0a0a] border border-[#1a1a1a] rounded-xl px-5 py-4 [&_summary::-webkit-details-marker]:hidden">
            <summary className="cursor-pointer flex justify-between items-center gap-4">
              <span className="font-semibold text-[15px]">It still shows the banner after Retry</span>
              <span className="text-[#666] group-open:rotate-45 transition-transform">+</span>
            </summary>
            <p className="mt-3 text-sm text-[#aaa] leading-relaxed">
              Verify Tokemon is actually on the list — open Get Info on the entry again and check the Access Control tab. If Tokemon isn&apos;t there, the Save didn&apos;t go through; redo step 6 and make sure you click <strong className="text-[#ededed]">Save Changes</strong>, not just close the window. If Tokemon is there but Retry still fails, quit Tokemon entirely (right-click menu bar icon → Quit) and relaunch.
            </p>
          </details>
          <details className="group bg-[#0a0a0a] border border-[#1a1a1a] rounded-xl px-5 py-4 [&_summary::-webkit-details-marker]:hidden">
            <summary className="cursor-pointer flex justify-between items-center gap-4">
              <span className="font-semibold text-[15px]">Will I have to do this every time?</span>
              <span className="text-[#666] group-open:rotate-45 transition-transform">+</span>
            </summary>
            <p className="mt-3 text-sm text-[#aaa] leading-relaxed">
              Only if Claude Code recreates the keychain entry — which usually means a fresh <code className="font-mono text-[#f0a060]">/login</code>. Routine token refreshes preserve the access list, so once you&apos;ve set this up Tokemon should keep working through normal Claude usage.
            </p>
          </details>
        </div>

        <div className="mt-14 p-6 bg-[#0a0a0a] border border-[#1a1a1a] rounded-xl">
          <h3 className="text-[15px] font-semibold mb-2">Still stuck?</h3>
          <p className="text-sm text-[#aaa] leading-relaxed mb-4">
            Open an issue on GitHub with your macOS version and a screenshot of the Access Control tab — happy to dig in.
          </p>
          <a href="https://github.com/richyparr/tokemon/issues/new" className="inline-flex items-center gap-2 px-5 py-2 rounded-md text-sm font-medium bg-[#ededed] text-black hover:opacity-85 transition-opacity">
            Open a GitHub issue
          </a>
        </div>
      </article>

      <footer className="border-t border-[#1a1a1a] py-10">
        <div className="max-w-[1080px] mx-auto px-6 flex flex-wrap gap-6 justify-between text-sm text-[#666]">
          <div>© 2026 Tokemon · MIT</div>
          <div className="flex gap-6">
            <Link href="/" className="hover:text-[#ededed] transition-colors">Home</Link>
            <Link href="/blog" className="hover:text-[#ededed] transition-colors">Blog</Link>
            <a href="https://github.com/richyparr/tokemon" className="hover:text-[#ededed] transition-colors">GitHub</a>
          </div>
        </div>
      </footer>
    </>
  );
}
