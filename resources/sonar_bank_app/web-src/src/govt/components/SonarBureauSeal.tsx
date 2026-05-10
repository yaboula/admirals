/**
 * SonarBureauSeal — SVG emblem for the SONAR Treasury Bureau.
 * Designed in 200×200 space, scaled via viewBox.
 * showText=true  → full seal with rope ring, stars, arced text (Bureau hero, 160px+)
 * showText=false → compact seal without text (sidebar, 52px)
 */
export function SonarBureauSeal({
  size = 160,
  showText = true,
}: {
  size?: number
  showText?: boolean
}) {
  const bgId = `sbg_${size}`
  const topArcId = `starc_${size}`

  const gold    = 'rgb(221, 167, 52)'
  const goldDim = 'rgba(221,167,52,0.5)'
  const navy    = 'rgb(0, 1, 2)'

  return (
    <svg
      width={size}
      height={size}
      viewBox="0 0 200 200"
      xmlns="http://www.w3.org/2000/svg"
      aria-hidden
    >
      <defs>
        <radialGradient id={bgId} cx="50%" cy="36%" r="68%">
          <stop offset="0%"   stopColor="rgb(2, 9, 22)" />
          <stop offset="100%" stopColor="rgb(0, 0, 1)" />
        </radialGradient>
        {showText && (
          <path
            id={topArcId}
            d="M 22,100 A 78,78 0 0 0 178,100"
          />
        )}
      </defs>

      {/* ── Outer rope / chain ring ── */}
      <circle
        cx="100" cy="100" r="95"
        fill="none"
        stroke={gold}
        strokeWidth="8"
        strokeDasharray="5.5 3.8"
        strokeLinecap="round"
        opacity="0.90"
      />

      {/* ── Outer gold ring (solid thin) ── */}
      <circle cx="100" cy="100" r="88" fill="none" stroke={gold} strokeWidth="1.2" opacity="0.50" />

      {/* ── Deep navy fill ── */}
      <circle cx="100" cy="100" r="87" fill={`url(#${bgId})`} />

      {/* ── Arced top text ── */}
      {showText && (
        <text
          fontSize="10.2"
          fontFamily="ui-sans-serif, system-ui, sans-serif"
          fontWeight="700"
          letterSpacing="2.6"
          fill={gold}
          opacity="0.88"
        >
          <textPath href={`#${topArcId}`} startOffset="50%" textAnchor="middle">
            SONAR TREASURY BUREAU
          </textPath>
        </text>
      )}

      {/* ── Side accent dots (left / right at y=100) ── */}
      {showText && (
        <>
          <circle cx="21.5" cy="100" r="2.5" fill={gold} opacity="0.75" />
          <circle cx="178.5" cy="100" r="2.5" fill={gold} opacity="0.75" />
        </>
      )}

      {/* ── Inner gold ring ── */}
      <circle
        cx="100" cy="100"
        r={showText ? 64 : 90}
        fill="none"
        stroke={gold}
        strokeWidth="1.2"
        opacity="0.50"
      />

      {/* ── Inner fill ── */}
      <circle cx="100" cy="100" r={showText ? 63 : 89} fill={navy} />

      {/* ── 3 stars at top ── */}
      {showText && (
        <>
          <Star cx={82}  cy={52} r={4.5} fill={gold} />
          <Star cx={100} cy={47} r={5.5} fill={gold} />
          <Star cx={118} cy={52} r={4.5} fill={gold} />
        </>
      )}

      {/* ── Monogram S (centered at 100,100) ── */}
      {/* Original paths designed in a translate(-29,-36) space so they render at (100,100) center */}
      <g transform="translate(-29,-36)">
        <path
          d="M124 108 Q158 108 158 132 Q158 156 124 156"
          fill="none"
          stroke={gold}
          strokeWidth={showText ? 5.5 : 7}
          strokeLinecap="round"
          opacity="0.35"
        />
        <path
          d="M124 122 Q148 122 148 136 Q148 150 124 150"
          fill="none"
          stroke={gold}
          strokeWidth={showText ? 5.5 : 7}
          strokeLinecap="round"
          opacity="0.65"
        />
        <path
          d="M100 136 Q110 122 124 122 Q138 122 138 136 Q138 150 124 150 Q108 150 100 164"
          fill="none"
          stroke={gold}
          strokeWidth={showText ? 6.5 : 8}
          strokeLinecap="round"
        />
      </g>

      {/* ── Decorative bottom dots (between S and bottom text) ── */}
      {showText && (
        <>
          <circle cx="79"  cy="144" r="1.3" fill={goldDim} />
          <circle cx="86"  cy="148" r="1.3" fill={goldDim} />
          <circle cx="100" cy="150" r="1.3" fill={goldDim} />
          <circle cx="114" cy="148" r="1.3" fill={goldDim} />
          <circle cx="121" cy="144" r="1.3" fill={goldDim} />
        </>
      )}

      {/* ── Bottom label ── */}
      {showText && (
        <text
          x="100"
          y="160"
          fontSize="8.2"
          fontFamily="ui-sans-serif, system-ui, sans-serif"
          fontWeight="700"
          letterSpacing="3.8"
          fill={goldDim}
          textAnchor="middle"
        >
          LOS SANTOS
        </text>
      )}
    </svg>
  )
}

function Star({
  cx,
  cy,
  r,
  fill,
}: {
  cx: number
  cy: number
  r: number
  fill: string
}) {
  const points = Array.from({ length: 10 }, (_, i) => {
    const angle = (i * 36 - 90) * (Math.PI / 180)
    const radius = i % 2 === 0 ? r : r * 0.42
    return `${cx + radius * Math.cos(angle)},${cy + radius * Math.sin(angle)}`
  }).join(' ')
  return <polygon points={points} fill={fill} />
}
