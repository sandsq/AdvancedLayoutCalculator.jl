function gen4x12keymap(o::Symbol; numlayers::Int=3, layerswitchmoveability=false)
    kmholder = Vector{Layer}()
    for i in 1:numlayers
        push!(kmholder, gentemplatelayer(4, 12))
    end
    if numlayers == 1
        return Keymap(kmholder; layerswitches=LayerSwitchmap(KeyLocation()), effortlayer=gen4x12effortlayer(), fingermaplayer=gen4x12fingermaplayer())
    end

    # place standard lower and raise layers in bottom row to the left and right of spacebar
    bottomrowsize = 12
    center = bottomrowsize % 2 == 0 ? convert(Int, bottomrowsize/2) : convert(Int, ceil(bottomrowsize/2))
    lowerpos = KeyLocation(1, (4, center-1))
    raiseoffset = bottomrowsize % 2 == 0 ? 2 : 1
    raisepos = KeyLocation(1, (4, center+raiseoffset))
    # @warn "manually checking if there is only 1 layer, which is a bit less general" maxlog=1

    fillerpos = fill(KeyLocation(), numlayers-3)
    lsm = numlayers == 2 ? LayerSwitchmap(KeyLocation(), lowerpos) : LayerSwitchmap(KeyLocation(), lowerpos, raisepos, fillerpos...)

    el = gen4x12effortlayer()
    fl = gen4x12fingermaplayer()

    km = Keymap(kmholder; layerswitches = lsm, effortlayer=el, fingermaplayer=fl)

    km[lowerpos] = Key(_LS, layerswitchmoveability)
    km[KeyLocation(2, gridposition(lowerpos))] = Key(_LS, layerswitchmoveability)

    if numlayers >= 3
        km[raisepos] = Key(_LS, layerswitchmoveability)
        km[KeyLocation(3, gridposition(raisepos))] = Key(_LS, layerswitchmoveability)

        km[KeyLocation(3, 4, 1)] = Key(nothing, false)
        km[KeyLocation(3, 4, 2)] = Key(nothing, false)
        km[KeyLocation(3, 4, 11)] = Key(nothing, false)
        km[KeyLocation(3, 4, 12)] = Key(nothing, false)
    end

    km[KeyLocation(1, 4, 1)] = Key(nothing, false)
    km[KeyLocation(1, 4, 2)] = Key(nothing, false)
    km[KeyLocation(1, 4, 11)] = Key(nothing, false)
    km[KeyLocation(1, 4, 12)] = Key(nothing, false)

    km[KeyLocation(2, 4, 1)] = Key(nothing, false)
    km[KeyLocation(2, 4, 2)] = Key(nothing, false)
    km[KeyLocation(2, 4, 11)] = Key(nothing, false)
    km[KeyLocation(2, 4, 12)] = Key(nothing, false)

    return km
end

function gen5x6keymap(;numlayers=3, template=:innerthumbbspc)
    @info "generating $numlayers layer version"
    kmholder = Vector{Layer{Key}}()

    v070fam = [:v070, :v071, :v073, :v075, :v055_2]

    if template == :innerthumbbspc
        l1 = layer"""
        __     __   __    __     __     __
        TAB@f     __   __     __     __     __
        __     __   __     LS   __     __
        LS@f     __   __     __     __     __
        GUI@f  CAPS@f   ALT@f   LS@f      BSPC@f  SPC@f
        """
        l2 = layer"""
        ESC@f  __   __    __     __     __
        __   __   __     __     __     __
        LCTL@f     __   __     LS     __     __
        __     __   __     __     __     __
        GUI@f    __@f   ALT@f   __@f    __@f     __
        """
        l3 = layer"""
        LPRN@f  RPRN@f   EQL@f  SLSH@f  ASTR@f  MINS@f
        LBRC@f  RBRC@f     1@f     2@f     3@f  PLUS@f
        LCBR@f  RCBR@f     4@f     5@f     6@f   ENT@f
        LS@f    COMM@f         7@f     8@f     9@f     UNDS@f
        __@f      __@f      COLN@f     0@f   DOT@f    __@f
        """
        l4 = layer"""
            __@f __@f __@f __@f __@f __@f
            F1@f F2@f F3@f F4@f F5@f F6@f
            __@f LEFT@f UP@f DOWN@f RGHT@f DEL@f
            SFT@f HOME@f PGUP@f PGDN@f END@f PSCR@f
            __@f __@f __@f LS@f __@f __@f
        """
        lsm = LayerSwitchmap(KeyLocation(), KeyLocation(1, 3, 4), KeyLocation(1, 4, 1), KeyLocation(1, 5, 4))
    elseif template == :standardthumbls
        l1 = layer"""
        LS@f     __   __     __     __     __
        TAB     __   __     __     __     __
        LCTL     S@f   __     __   __     __
        __     __   __     __     __     LS
        __  CAPS   GUI   ALT      LS@f  SPC@f
        """
        l2 = layer"""
        ESC  __   __     __     __     GRV@f
        TAB   __   __     __     __     __
        LCTL     __   __     __     __     __
        __     __   __     __     __     __
        __    __   GUI   __    LS@f     __
        """
        l3 = layer"""
        LPRN  RPRN   EQL  SLSH  ASTR  MINS
        LBRC  RBRC     1     2     3  PLUS
        LCBR  RCBR     4     5     6   ENT
        UNDS@f    __   7     8     9    LS
        __    __  COLN     0   DOT     MINS@f
        """
        l4 = layer"""
            LS@f __@f __@f __@f __@f __@f
            F1@f F2@f F3@f F4@f F5@f F6@f
            __@f LEFT@f UP@f DOWN@f RGHT@f DEL@f
            SFT@f HOME@f PGUP@f PGDN@f END@f PSCR@f
            __@f __@f __@f __@f LS __@f
        """
        lsm = LayerSwitchmap(KeyLocation(), KeyLocation(1, 5, 5), KeyLocation(1, 4, 6), KeyLocation(1, 1, 1))
    elseif template == :v070
        l1 = layer"""
        __     __   __     __     __     __
        TAB     __   __     __     __     __
        LCTL     __   __     __   LS     __
        LS@f     __   __     __     __     __
        GUI@f  CAPS@f   ALT@f   LS@f   BSPC@f  SPC@f
        """
        l1[KL(1, 5, 1)] = Key(_GUI, false)
        l1[KL(1, 5, 3)] = Key(_ALT, false)
        l1[KL(1, 4, 1)] = Key(_LS, false)
        l1[KL(1, 5, 4)] = Key(_LS, false)
        l2 = layer"""
        ESC  __   __     __     __     GRV@f
        __   __   __     __     __     __
        LCTL     __   __     __     LS     __
        __     __   __     __     __     __
        GUI@f    __@f   ALT@f   __    __     __
        """
        l2[KL(1, 5, 1)] = Key(_GUI, false)
        l2[KL(1, 5, 3)] = Key(_ALT, false)
        l2[KL(1, 1, 6)] = Key(_GRV, false)
        l2[KL(1, 5, 2)] = Key(nothing, false)
        l3 = layer"""
        LPRN@f  RPRN@f   EQL@f  SLSH@f  ASTR@f  MINS@f
        LBRC@f  RBRC@f     1@f     2@f     3@f  PLUS@f
        LCBR@f  RCBR@f     4@f     5@f     6@f   ENT@f
        LS@f    COMM@f         7@f     8@f     9@f      __
        __      __      COLN@f     0@f   DOT@f    __@f
        """
        l4 = layer"""
            __@f   __@f    __@f  __@f   __@f  __@f
            F1@f   F2@f   F3@f   F4@f   F5@f  F6@f
            __@f LEFT@f   UP@f DOWN@f RGHT@f DEL@f
           SFT@f HOME@f PGUP@f PGDN@f END@f PSCR@f
            __@f  __@f    __@f   LS@f  __@f   __@f
        """
        lsm = LayerSwitchmap(KeyLocation(), KeyLocation(1, 3, 5), KeyLocation(1, 4, 1), KeyLocation(1, 5, 4))
    
    elseif template == :v071
        l1 = layer"""
        X     J   SFT   DOT  COMM     D
        TAB  QUOT     S     I     A     B
        LCTL     W    LS     E     H     V
        LS@f     M     T     A  BSPC     P
        GUI@f  CAPS@f   ALT@f    LS@f     T   SPC@f
        """
        l1[KL(1, 5, 1)] = Key(_GUI, false)
        l1[KL(1, 5, 3)] = Key(_ALT, false)
        l1[KL(1, 4, 1)] = Key(_LS, false)
        l1[KL(1, 5, 4)] = Key(_LS, false)
        l2 = layer"""
        ESC    __    __  SLSH     L   GRV@f
        MINS     K     Q     G     U     S
        LCTL     N    LS     O     I     F
            B     Y  UNDS   ENT     D  SCLN
        GUI@f    __@f   ALT@f     C     L     R
        """
        l2[KL(1, 5, 1)] = Key(_GUI, false)
        l2[KL(1, 5, 3)] = Key(_ALT, false)
        l2[KL(1, 1, 6)] = Key(_GRV, false)
        l2[KL(1, 5, 2)] = Key(nothing, false)
        l3 = layer"""
        LPRN@f  RPRN@f   EQL@f  SLSH@f  ASTR@f  MINS@f
        LBRC@f  RBRC@f     1@f     2@f     3@f  PLUS@f
        LCBR@f  RCBR@f     4@f     5@f     6@f   ENT@f
        LS@f    COMM@f     7@f     8@f     9@f      Z
        __      __      COLN@f     0@f   DOT@f   __@f
        """
        l4 = layer"""
            __@f   __@f    __@f  __@f   __@f  __@f
            F1@f   F2@f   F3@f   F4@f   F5@f  F6@f
            __@f LEFT@f   UP@f DOWN@f RGHT@f DEL@f
           SFT@f HOME@f PGUP@f PGDN@f END@f PSCR@f
            __@f  __@f    __@f   LS@f  __@f   __@f
        """
        lsm = LayerSwitchmap(KeyLocation(), KeyLocation(1, 3, 3), KeyLocation(1, 4, 1), KeyLocation(1, 5, 4))
    elseif template == :v072
        l1 = layer"""
        X     J   SFT   DOT  COMM  SCLN
        TAB  QUOT     S     I     A     B
        LCTL     W    LS     E     H     V
        LS     I     T     A     M     P
        GUI  CAPS   ALT    LS     T   SPC
        """
        l1[KL(1, 5, 1)] = Key(_GUI, false)
        l1[KL(1, 5, 3)] = Key(_ALT, false)
        l1[KL(1, 4, 1)] = Key(_LS, false)
        l1[KL(1, 5, 4)] = Key(_LS, false)
        l2 = layer"""
        ESC    __  SLSH     L   SPC   GRV
        MINS     S     Q     G     U     K
        LCTL     N    LS     O     D     F
        B     Y     Z   ENT  BSPC     E
        GUI    __   ALT     C     L     R
        """
        l2[KL(1, 5, 1)] = Key(_GUI, false)
        l2[KL(1, 5, 3)] = Key(_ALT, false)
        l2[KL(1, 1, 6)] = Key(_GRV, false)
        l2[KL(1, 5, 2)] = Key(nothing, false)
        l3 = layer"""
        LPRN@f  RPRN@f   EQL@f  SLSH@f  ASTR@f  MINS@f
        LBRC@f  RBRC@f     1@f     2@f     3@f  PLUS@f
        LCBR@f  RCBR@f     4@f     5@f     6@f   ENT@f
        LS@f    COMM@f     7@f     8@f     9@f   UNDS
        __      __      COLN@f     0@f   DOT@f   __@f
        """
        l4 = layer"""
            __@f   __@f    __@f  __@f   __@f  __@f
            F1@f   F2@f   F3@f   F4@f   F5@f  F6@f
            __@f LEFT@f   UP@f DOWN@f RGHT@f DEL@f
           SFT@f HOME@f PGUP@f PGDN@f END@f PSCR@f
            __@f  __@f    __@f   LS@f  __@f   __@f
        """
        lsm = LayerSwitchmap(KeyLocation(), KeyLocation(1, 3, 3), KeyLocation(1, 4, 1), KeyLocation(1, 5, 4))
    elseif template == :v073
        l1 = layer"""
        SLSH  UNDS     F   SFT  QUOT  SCLN
        TAB     B     S     O     R     M
        LCTL     T     H     E     A     I
        LS     W     V   SFT  BSPC     P
        GUI  CAPS   ALT    LS    LS   SPC
        """
        l1[KL(1, 5, 1)] = Key(_GUI, false)
        l1[KL(1, 5, 3)] = Key(_ALT, false)
        l1[KL(1, 4, 1)] = Key(_LS, false)
        l1[KL(1, 5, 4)] = Key(_LS, false)
        l1[KL(1, 5, 2)] = Key(_CAPS, false)
        l1[KL(1, 5, 6)] = Key(_SPC, false)

        l2 = layer"""
        ESC     Z   DOT  MINS  COMM   GRV
        Q     R   ENT     L     D     S
        LCTL     I     N     G     U     L
        X     M     Y     O     C     K
        GUI    __   ALT    __    LS     J
        """
        l2[KL(1, 5, 1)] = Key(_GUI, false)
        l2[KL(1, 5, 3)] = Key(_ALT, false)
        l2[KL(1, 1, 6)] = Key(_GRV, false)
        l2[KL(1, 5, 2)] = Key(nothing, false)
        l2[KL(1, 5, 5)] = Key(_LS, false)

        l3 = layer"""
        LPRN@f  RPRN@f   EQL@f  SLSH@f  ASTR@f  MINS@f
        LBRC@f  RBRC@f     1@f     2@f     3@f  PLUS@f
        LCBR@f  RCBR@f     4@f     5@f     6@f   ENT@f
        LS@f    __@f     7@f     8@f     9@f      __
        __      __      COLN@f     0@f   DOT@f    __@f
        """
        # 5, 6 is shift; 4, 2 is comma
        l4 = layer"""
            __@f   __@f    __@f  __@f   __@f  __@f
            F1@f   F2@f   F3@f   F4@f   F5@f  F6@f
            __@f LEFT@f   UP@f DOWN@f RGHT@f DEL@f
           SFT@f HOME@f PGUP@f PGDN@f END@f PSCR@f
            __@f  __@f    __@f   LS@f  __@f   __@f
        """
        lsm = LayerSwitchmap(KeyLocation(), KeyLocation(1, 5, 5), KeyLocation(1, 4, 1), KeyLocation(1, 5, 4))
    elseif template == :v075
        l1 = layer"""
        UNDS     J  COMM     R     F  SCLN
        TAB     C     O     S     M     S
        LCTL     R     E    LS     U     W
            LS     B   SFT  QUOT   ENT   DOT
        GUI  CAPS   ALT    LS  BSPC@f   SPC
        """
        l1[KL(1, 5, 1)] = Key(_GUI, false)
        l1[KL(1, 5, 3)] = Key(_ALT, false)
        l1[KL(1, 4, 1)] = Key(_LS, false)
        l1[KL(1, 5, 4)] = Key(_LS, false)
        l1[KL(1, 5, 2)] = Key(_CAPS, false)
        l1[KL(1, 5, 6)] = Key(_SPC, false)

        l2 = layer"""
        ESC    __     L    __     O   GRV
        MINS     K     I     X     Y     P
        LCTL     H     A    LS     T     V
            Q     I     G  SLSH     D   SPC
        GUI    __   ALT   ENT     L     N
        """
        l2[KL(1, 5, 1)] = Key(_GUI, false)
        l2[KL(1, 5, 3)] = Key(_ALT, false)
        l2[KL(1, 1, 6)] = Key(_GRV, false)
        l2[KL(1, 5, 2)] = Key(nothing, false)
        

        l3 = layer"""
        LPRN@f  RPRN@f   EQL@f  SLSH@f  ASTR@f  MINS@f
        LBRC@f  RBRC@f     1@f     2@f     3@f  PLUS@f
        LCBR@f  RCBR@f     4@f     5@f     6@f   ENT@f
        LS@f    __@f     7@f     8@f     9@f      Z
        __      __      COLN@f     0@f   DOT@f    __@f
        """
        # 5, 6 is shift; 4, 2 is comma
        l4 = layer"""
            __@f   __@f    __@f  __@f   __@f  __@f
            F1@f   F2@f   F3@f   F4@f   F5@f  F6@f
            __@f LEFT@f   UP@f DOWN@f RGHT@f DEL@f
           SFT@f HOME@f PGUP@f PGDN@f END@f PSCR@f
            __@f  __@f    __@f   LS@f  __@f   __@f
        """
        lsm = LayerSwitchmap(KeyLocation(), KeyLocation(1, 3, 4), KeyLocation(1, 4, 1), KeyLocation(1, 5, 4))


    elseif template == :v090
        l1 = layer"""
        __     __   __     __     __     __
        TAB@f     __   __     __     __     __
        LCTL@f     __   __     __   LS     __
        LS@f     __   __     __     __     __
        GUI@f  CAPS@f   ALT@f   LS@f   BSPC  SPC@f
        """

        l2 = layer"""
        ESC@f  __   __     __     __     GRV@f
        __   __   __     __     __     __
        LCTL@f     __   __     __     LS     __
        __     __   __     __     __     __
        GUI@f    __@f   ALT@f   __    __     __
        """

        l3 = layer"""
        LPRN@f  RPRN@f   EQL@f  SLSH@f  ASTR@f  MINS@f
        LBRC@f  RBRC@f     1@f     2@f     3@f  PLUS@f
        LCBR@f  RCBR@f     4@f     5@f     6@f   ENT@f
        LS@f    COMM@f     7@f     8@f     9@f      __
        __      __      COLN@f     0@f   DOT@f    __@f
        """
        l4 = layer"""
            __@f   __@f    __@f  __@f   __@f  __@f
            F1@f   F2@f   F3@f   F4@f   F5@f  F6@f
            __@f LEFT@f   UP@f DOWN@f RGHT@f DEL@f
           SFT@f HOME@f PGUP@f PGDN@f END@f PSCR@f
            __@f  __@f    __@f   LS@f  __@f   __@f
        """
        lsm = LayerSwitchmap(KeyLocation(), KeyLocation(1, 3, 5), KeyLocation(1, 4, 1), KeyLocation(1, 5, 4))

    elseif template == :v1
            # 15.908
        l1 = layer"""
            O     N   X     T     U     Y
            TAB     I     N     T     H     G
            LCTL     A   SPC     E    LS     R
            Q     M     L     O     F    LS
            __    CAPS   GUI   ALT  BSPC   S  
        """
        l2 = layer"""
            ESC     D     K  SCLN     A    GRV@f
            TAB     C   SFT     W     V    K
            LCTL  COMM   ENT     D    LS     Z
            __   DOT  QUOT     L     J     B
            __    __   GUI   ALT   LS@f   P
        """
        l3 = layer"""
            LPRN  RPRN   EQL  SLSH  ASTR  MINS
            LBRC  RBRC     1     2     3  PLUS
            LCBR  RCBR     4     5     6   ENT
            UNDS@f    __     7     8     9    LS
            __    __  COLN     0   DOT     MINS@f
        """
        l4 = layer"""
            __@f __@f __@f __@f __@f __@f
            F1@f F2@f F3@f F4@f F5@f F6@f
            __@f LEFT@f UP@f DOWN@f RGHT@f DEL@f
            SFT@f HOME@f PGUP@f PGDN@f END@f PSCR@f
            __@f __@f __@f __@f LS@f __@f
        """
        lsm = LayerSwitchmap(KeyLocation(), KeyLocation(1, 3, 5), KeyLocation(1, 4, 6), KeyLocation(2, 5, 5))
    elseif template == :v2
                # 16.87
        l1 = layer"""
            F     R     W     O   SPC     V
            TAB     S     I     A     H     W
            LCTL     T   SPC     E    LS     F
            QUOT     R     O     U     B    LS
            __  CAPS   GUI   ALT  BSPC     D
        """
        l2 = layer"""
            ESC     Q     P     Y     Z    GRV@f
            TAB     M     L     G  K      X
            LCTL  COMM   SFT     N    LS     J
            SCLN   DOT   ENT     S  SLSH    __
            __    __   GUI   ALT    LS@f     C
        """
        l3 = layer"""
            LPRN  RPRN   EQL  SLSH  ASTR  MINS
            LBRC  RBRC     1     2     3  PLUS
            LCBR  RCBR     4     5     6   ENT
            UNDS@f    __     7     8     9    LS
            __    __  COLN     0   DOT     MINS@f
        """
        l4 = layer"""
            __@f __@f __@f __@f __@f __@f
            F1@f F2@f F3@f F4@f F5@f F6@f
            __@f LEFT@f UP@f DOWN@f RGHT@f DEL@f
            SFT@f HOME@f PGUP@f PGDN@f END@f PSCR@f
            __@f __@f __@f __@f LS@f __@f
        """
        lsm = LayerSwitchmap(KeyLocation(), KeyLocation(1, 3, 5), KeyLocation(1, 4, 6), KeyLocation(2, 5, 5))
    elseif template == :v3
        l1 = layer"""
        MINS     B     U     G   SPC     A
        TAB     I     N     T     H     D
       LCTL     A   SPC     E    LS  COMM
          T   DOT     R     F     M    LS
         __  CAPS   GUI   ALT  BSPC     O
        """
        l2 = layer"""
        ESC     Q     B  QUOT     J   GRV@f
        TAB     V   SFT     W     P     Z
       LCTL     R     L     S    LS     X
          D  SCLN     C     Y     K    __
         __    __   GUI   ALT    LS   ENT
        """
        l3 = layer"""
        LPRN  RPRN   EQL  SLSH  ASTR  MINS
        LBRC  RBRC     1     2     3  PLUS
        LCBR  RCBR     4     5     6   ENT
        UNDS@f  __     7     8     9    LS
          __    __  COLN     0   DOT     MINS@f
        """
        l4 = layer"""
            __@f __@f __@f __@f __@f __@f
            F1@f F2@f F3@f F4@f F5@f F6@f
            __@f LEFT@f UP@f DOWN@f RGHT@f DEL@f
            SFT@f HOME@f PGUP@f PGDN@f END@f PSCR@f
            __@f __@f __@f __@f LS@f __@f
        """
        lsm = LayerSwitchmap(KeyLocation(), KeyLocation(1, 3, 5), KeyLocation(1, 4, 6), KeyLocation(2, 5, 5))
    elseif template == :v4
        # 17.222332, 
        l1 = layer"""
        COMM     D     U   SPC     C     Y
        TAB     W     H     I     T     V
       LCTL     E   SPC     A    LS  COMM
          Z    D     N     F     M     LS
         __  CAPS   GUI   ALT  BSPC     O
        """
        l2 = layer"""
        ESC  Q  QUOT     B     X   GRV@f
        TAB   SFT     L     S     K    SCLN
       LCTL     G     R     N    LS  SLSH
          J   DOT     E     P  UNDS    __
         __    __   GUI   ALT    LS@f   ENT
        """
        l3 = layer"""
        LPRN  RPRN   EQL  SLSH  ASTR  MINS
        LBRC  RBRC     1     2     3  PLUS
        LCBR  RCBR     4     5     6   ENT
        UNDS@f  __     7     8     9     LS
          __    __  COLN     0   DOT     MINS@f
        """
        l4 = layer"""
            __@f __@f __@f __@f __@f __@f
            F1@f F2@f F3@f F4@f F5@f F6@f
            __@f LEFT@f UP@f DOWN@f RGHT@f DEL@f
            SFT@f HOME@f PGUP@f PGDN@f END@f PSCR@f
            __@f __@f __@f __@f LS@f __@f
        """
        lsm = LayerSwitchmap(KeyLocation(), KeyLocation(1, 3, 5), KeyLocation(1, 4, 6), KeyLocation(2, 5, 5))
    elseif template == :v5
        # 15.814 initial keymaps from blank template, different rng seed
        l1 = layer"""
        Q   DOT   SFT     D   SPC  QUOT
        TAB     E     H     T     I  COMM
       LCTL     W   SPC    LS     A     G
       SCLN     M     I     N     F    LS
         __  CAPS   GUI   ALT  BSPC     O
        """
        l2 = layer"""
        ESC  SLSH     P     Z     M   GRV@f
        TAB   ENT     N     X     E     Y
       LCTL     S     L    LS     R     U
          J     V     B  UNDS   DOT     K
         __    __   GUI   ALT    LS@f     C
        """
        l3 = layer"""
        LPRN  RPRN   EQL  SLSH  ASTR  MINS
        LBRC  RBRC     1     2     3  PLUS
        LCBR  RCBR     4     5     6   ENT
        UNDS@f  __     7     8     9    LS
          __    __  COLN     0   DOT  MINS@f
        """
        l4 = layer"""
            __@f __@f __@f __@f __@f __@f
            F1@f F2@f F3@f F4@f F5@f F6@f
            __@f LEFT@f UP@f DOWN@f RGHT@f DEL@f
            SFT@f HOME@f PGUP@f PGDN@f END@f PSCR@f
            __@f __@f __@f __@f LS@f __@f
        """
        lsm = LayerSwitchmap(KeyLocation(), KeyLocation(1, 3, 4), KeyLocation(1, 4, 6), KeyLocation(2, 5, 5))
    elseif template == :v6
        # 15.806 initial keymaps from blank template, different rng seed
        l1 = layer"""
          J   DOT   SFT     D   SPC  QUOT
        TAB     E     H     T     I  COMM
       LCTL     W   SPC    LS     A     G
       SCLN     M     I     N     F    LS
         __  CAPS   GUI   ALT  BSPC     O
        """
        l2 = layer"""
        ESC     X     K     Z     M   GRV@f
        TAB   ENT     N     Q     E     Y
       LCTL     S     L    LS     R     U
       SLSH     V     B    __     P   DOT
         __    __   GUI   ALT    LS     C
        """
        l3 = layer"""
        LPRN  RPRN   EQL  SLSH  ASTR  MINS
        LBRC  RBRC     1     2     3  PLUS
        LCBR  RCBR     4     5     6   ENT
        UNDS@f    __     7     8     9    LS
          __    __  COLN     0   DOT  MINS@f
        """
        l4 = layer"""
            __@f   __@f   __@f   __@f   __@f  __@f
            F1@f   F2@f   F3@f   F4@f   F5@f  F6@f
            __@f LEFT@f   UP@f DOWN@f RGHT@f DEL@f
           SFT@f HOME@f PGUP@f PGDN@f END@f PSCR@f
            __@f __@f   __@f   __@f  LS@f   __@f
        """
        lsm = LayerSwitchmap(KeyLocation(), KeyLocation(1, 3, 4), KeyLocation(1, 4, 6), KeyLocation(2, 5, 5))
    elseif template == :v7
        l1 = layer"""
          X     J     Y   ENT   DOT  SCLN
        TAB     G     N   SPC     D  COMM
       LCTL     A    LS     H     T     W
          B     S   SPC     F     R    LS
         __  CAPS   GUI   ALT  BSPC     O
        """
        l2 = layer"""
        ESC    __     Z     U  COMM   GRV@f
        TAB  QUOT     B     I     S     V
       LCTL   SPC    LS     E     L     M
          K   ENT     Q   SFT     C     P
         __    __   GUI   ALT    LS@f     U
        """
        l3 = layer"""
        LPRN  RPRN   EQL  SLSH  ASTR  MINS
        LBRC  RBRC     1     2     3  PLUS
        LCBR  RCBR     4     5     6   ENT
        UNDS@f    __   7     8     9    LS
          __    __  COLN     0   DOT   MINS@f
        """
        l4 = layer"""
            __@f   __@f   __@f   __@f   __@f  __@f
            F1@f   F2@f   F3@f   F4@f   F5@f  F6@f
            __@f LEFT@f   UP@f DOWN@f RGHT@f DEL@f
           SFT@f HOME@f PGUP@f PGDN@f END@f PSCR@f
            __@f __@f   __@f   __@f  LS@f   __@f
        """
        lsm = LayerSwitchmap(KeyLocation(), KeyLocation(1, 3, 3), KeyLocation(1, 4, 6), KeyLocation(2, 5, 5))
    elseif template == :v8
        l1 = layer"""
        SLSH     J  SCLN     I  COMM     Y
        TAB     G     N   SPC     D     B
       LCTL     A    LS     H     T     W
        DOT     S   SPC     O     R    LS
         __  CAPS   GUI   ALT  BSPC     F
        """
        l2 = layer"""
        ESC    __     Z  QUOT     K   GRV@f
        TAB     O     Q     L     S     V
       LCTL     I    LS     E   SPC   ENT
       COMM   SFT     X     U     M     P
         __    __   GUI   ALT    LS     C
        """
        l3 = layer"""
        LPRN  RPRN   EQL  SLSH  ASTR  MINS
        LBRC  RBRC     1     2     3  PLUS
        LCBR  RCBR     4     5     6   ENT
        UNDS@f    __   7     8     9    LS
          __    __  COLN     0   DOT  MINS@f
        """
        l4 = layer"""
            __@f   __@f   __@f   __@f   __@f  __@f
            F1@f   F2@f   F3@f   F4@f   F5@f  F6@f
            __@f LEFT@f   UP@f DOWN@f RGHT@f DEL@f
           SFT@f HOME@f PGUP@f PGDN@f END@f PSCR@f
            __@f __@f   __@f   __@f  LS@f   __@f
        """
        lsm = LayerSwitchmap(KeyLocation(), KeyLocation(1, 3, 3), KeyLocation(1, 4, 6), KeyLocation(2, 5, 5))
    elseif template == :v9
        l1 = layer"""
        X     J     Y   ENT   DOT      E
        TAB     G     N   SPC     D  COMM
       LCTL     A    LS     H     T     W
          B     S   SPC     F     R    LS
         __  CAPS   GUI   ALT  BSPC     O
        """
        l2 = layer"""
        ESC    SCLN     Z     U  COMM   GRV@f
        TAB  QUOT  B     I     S     V
       LCTL   SPC    LS     E     L     M
          K   ENT     Q   SFT     C     P
         __    __   GUI   ALT    LS     U
        """
        l3 = layer"""
        LPRN  RPRN   EQL  SLSH  ASTR  MINS
        LBRC  RBRC     1     2     3  PLUS
        LCBR  RCBR     4     5     6   ENT
        UNDS@f    __   7     8     9    LS
          __    __  COLN     0   DOT  MINS@f
        """
        l4 = layer"""
            __@f   __@f   __@f   __@f   __@f  __@f
            F1@f   F2@f   F3@f   F4@f   F5@f  F6@f
            __@f LEFT@f   UP@f DOWN@f RGHT@f DEL@f
           SFT@f HOME@f PGUP@f PGDN@f END@f PSCR@f
            __@f __@f   __@f   __@f  LS@f   __@f
        """
        lsm = LayerSwitchmap(KeyLocation(), KeyLocation(1, 3, 3), KeyLocation(1, 4, 6), KeyLocation(2, 5, 5))
    elseif template == :v10
        l1 = layer"""
        DOT  SLSH   SFT   ENT   SPC  QUOT
        TAB     E     H     T     I     T
       LCTL     G     E    LS     A     W
        SFT     V     I     D     N    LS
         __  CAPS   GUI   ALT  BSPC   SPC
        """
        l2 = layer"""
        ESC     Z     J     X   ENT   GRV@f
        TAB     K     F     P     S     C
       LCTL     L     O    LS     R     U
       SCLN     B     N     Q     M  COMM
         __    __   GUI   ALT    LS     Y
        """
        l3 = layer"""
        LPRN  RPRN   EQL  SLSH  ASTR  MINS
        LBRC  RBRC     1     2     3  PLUS
        LCBR  RCBR     4     5     6   ENT
        UNDS@f    __   7     8     9    LS
          __    __  COLN     0   DOT  MINS@f
        """
        l4 = layer"""
            __@f   __@f   __@f   __@f   __@f  __@f
            F1@f   F2@f   F3@f   F4@f   F5@f  F6@f
            __@f LEFT@f   UP@f DOWN@f RGHT@f DEL@f
           SFT@f HOME@f PGUP@f PGDN@f END@f PSCR@f
            __@f __@f   __@f   __@f  LS@f   __@f
        """
        lsm = LayerSwitchmap(KeyLocation(), KeyLocation(1, 3, 4), KeyLocation(1, 4, 6), KeyLocation(2, 5, 5))
    elseif template == :v11
        l1 = layer"""
        DOT  SLSH   SFT   ENT   SPC  QUOT
        TAB     E     H     T     I     L
        LCTL     L     E    LS     A     W
        P     V     I     D     N    LS
        __  CAPS   GUI   ALT  BSPC   SPC
        """
        l2 = layer"""
        ESC     Z     J   SPC     X   GRV@f
        TAB     B     Y     U     S     T
        LCTL     R     O    LS     G     C
        SCLN     M     N     Q     F  COMM
        __    __   GUI   ALT    LS     K
        """
        l3 = layer"""
        LPRN  RPRN   EQL  SLSH  ASTR  MINS
        LBRC  RBRC     1     2     3  PLUS
        LCBR  RCBR     4     5     6   ENT
        UNDS@f    __   7     8     9    LS
          __    __  COLN     0   DOT  MINS@f
        """
        l4 = layer"""
            __@f   __@f   __@f   __@f   __@f  __@f
            F1@f   F2@f   F3@f   F4@f   F5@f  F6@f
            __@f LEFT@f   UP@f DOWN@f RGHT@f DEL@f
           SFT@f HOME@f PGUP@f PGDN@f END@f PSCR@f
            __@f __@f   __@f   __@f  LS@f   __@f
        """
        lsm = LayerSwitchmap(KeyLocation(), KeyLocation(1, 3, 4), KeyLocation(1, 4, 6), KeyLocation(2, 5, 5))
    elseif template == :v12
        l1 = layer"""
        DOT  SLSH   SFT   ENT   SPC  QUOT
        TAB     E     H     T     I     W
       LCTL     L     E    LS     A     F
          P     V     L     D     M    LS
         __  CAPS   GUI   ALT  BSPC   SPC
        """
        l2 = layer"""
        ESC     Z     Q     X     Y   GRV@f
        TAB     C     S     W     N     S
       LCTL     U     O    LS     R     G
       COMM     I     N  SCLN     B     K
         __    __   GUI     J    LS     Y
        """
        l3 = layer"""
        LPRN  RPRN   EQL  SLSH  ASTR  MINS
        LBRC  RBRC     1     2     3  PLUS
        LCBR  RCBR     4     5     6   ENT
        UNDS@f    __   7     8     9    LS
          __    __  COLN     0   DOT  MINS@f
        """
        l4 = layer"""
            __@f   __@f   __@f   __@f   __@f  __@f
            F1@f   F2@f   F3@f   F4@f   F5@f  F6@f
            __@f LEFT@f   UP@f DOWN@f RGHT@f DEL@f
           SFT@f HOME@f PGUP@f PGDN@f END@f PSCR@f
            __@f __@f   __@f   __@f  LS@f   __@f
        """
        lsm = LayerSwitchmap(KeyLocation(), KeyLocation(1, 3, 4), KeyLocation(1, 4, 6), KeyLocation(2, 5, 5))
    elseif template == :v055
        # e8823cd0
        l1 = layer"""
        DOT  SLSH   SFT   ENT   SPC  QUOT
        TAB     E     H     T     I     P
       LCTL     S     E    LS     A     W
          B     F     I     V     N    LS
         __  CAPS   GUI   ALT  BSPC   SPC
        """
        l2 = layer"""
        ESC     Z     Q     X     L   GRV@f
        TAB     D     L     B     U     T
       LCTL     G     O    LS     R     C
       COMM     D     N  SCLN     M     K
         __    __   GUI     J    LS     Y
        """
        l3 = layer"""
        LPRN  RPRN   EQL  SLSH  ASTR  MINS
        LBRC  RBRC     1     2     3  PLUS
        LCBR  RCBR     4     5     6   ENT
        UNDS@f    __   7     8     9    LS
          __    __  COLN     0   DOT  MINS@f
        """
        l4 = layer"""
            __@f   __@f   __@f   __@f   __@f  __@f
            F1@f   F2@f   F3@f   F4@f   F5@f  F6@f
            __@f LEFT@f   UP@f DOWN@f RGHT@f DEL@f
           SFT@f HOME@f PGUP@f PGDN@f END@f PSCR@f
            __@f __@f   __@f   __@f  LS@f   __@f
        """
        lsm = LayerSwitchmap(KeyLocation(), KeyLocation(1, 3, 4), KeyLocation(1, 4, 6), KeyLocation(2, 5, 5))
    elseif template == :v055_2
        # e8823cd0
        l1 = layer"""
        DOT  SLSH   SFT   ENT   SPC  QUOT
        TAB@f     E     H     T     I     P
        LCTL@f     S     E    LS     A     W
        LS@f     F     I     V     N    COMM
        GUI@f  CAPS@f   ALT@f   LS@f  BSPC@f   SPC@f
        """
        l2 = layer"""
        ESC@f     Z     Q     X     J   GRV@f
        __     D     L     B     U     T
       LCTL@f     G     O    LS     R     C
       COMM     D     N  SCLN     M     K
        GUI@f    __@f  ALT@f  __@f    __@f   Y
        """
        l3 = layer"""
        LPRN@f  RPRN@f   EQL@f  SLSH@f  ASTR@f  MINS@f
        LBRC@f  RBRC@f     1@f     2@f     3@f  PLUS@f
        LCBR@f  RCBR@f     4@f     5@f     6@f   ENT@f
        LS@f    COMM@f     7@f     8@f     9@f  UNDS@f
        __@f      __@f  COLN@f     0@f   DOT@f    __@f
        """
        l4 = layer"""
            __@f   __@f   __@f   __@f   __@f  __@f
            F1@f   F2@f   F3@f   F4@f   F5@f  F6@f
            __@f LEFT@f   UP@f DOWN@f RGHT@f DEL@f
           SFT@f HOME@f PGUP@f PGDN@f END@f PSCR@f
            __@f __@f   __@f   LS@f  __@f   __@f
        """
        lsm = LayerSwitchmap(KeyLocation(), KeyLocation(1, 3, 4), KeyLocation(1, 4, 1), KeyLocation(1, 5, 4))
    elseif template == :v056
        
        l1 = layer"""
        DOT  SLSH   SFT   ENT   SPC  QUOT
        TAB     E     H     T     I     P
       LCTL     S     E    LS     A     W
          B     F     I     V     N    LS
         __  CAPS   GUI   ALT  BSPC   SPC
        """
        l2 = layer"""
        ESC     Z     Q     X     J   GRV@f
        TAB     D     L     B     U     T
       LCTL     G     O    LS     R     C
       COMM     D     N  SCLN     M     K
         __    __   GUI   ALT    LS     Y
        """
        l3 = layer"""
        LPRN  RPRN   EQL  SLSH  ASTR  MINS
        LBRC  RBRC     1     2     3  PLUS
        LCBR  RCBR     4     5     6   ENT
        UNDS@f    __   7     8     9    LS
          __    __  COLN     0   DOT  MINS@f
        """
        l4 = layer"""
            __@f   __@f   __@f   __@f   __@f  __@f
            F1@f   F2@f   F3@f   F4@f   F5@f  F6@f
            __@f LEFT@f   UP@f DOWN@f RGHT@f DEL@f
           SFT@f HOME@f PGUP@f PGDN@f END@f PSCR@f
            __@f __@f   __@f   __@f  LS@f   __@f
        """
        lsm = LayerSwitchmap(KeyLocation(), KeyLocation(1, 3, 4), KeyLocation(1, 4, 6), KeyLocation(2, 5, 5))
    elseif template == :v057
        # 1d74f660
        l1 = layer"""
        DOT  SLSH   SFT   SPC  QUOT     D
        TAB     W     A     T     I     B
        LCTL     S     E    LS     H     V
            F     C     I     M     L    LS
            __  CAPS   GUI   ALT  BSPC     T
        """
        l2 = layer"""
        ESC     Z     K     X     K   GRV@f
        COMM     Y   SPC  SCLN     N     F
        LCTL     G     O    LS     R   ENT
            P     D     N     Q     U   SPC
            __    __   GUI     J    LS     L
        """
        l3 = layer"""
        LPRN  RPRN   EQL  SLSH  ASTR  MINS
        LBRC  RBRC     1     2     3  PLUS
        LCBR  RCBR     4     5     6   ENT
        UNDS@f    __   7     8     9    LS
          __    __  COLN     0   DOT  MINS@f
        """
        l4 = layer"""
            __@f   __@f   __@f   __@f   __@f  __@f
            F1@f   F2@f   F3@f   F4@f   F5@f  F6@f
            __@f LEFT@f   UP@f DOWN@f RGHT@f DEL@f
           SFT@f HOME@f PGUP@f PGDN@f END@f PSCR@f
            __@f __@f   __@f   __@f  LS@f   __@f
        """
        lsm = LayerSwitchmap(KeyLocation(), KeyLocation(1, 3, 4), KeyLocation(1, 4, 6), KeyLocation(2, 5, 5))
    elseif template == :v058
        # 8c26334e
        l1 = layer"""
        Q  SLSH   SFT   ENT   SPC  QUOT
        TAB     E     H     T     W     B
        LCTL     S     E    LS     A     I
            P     V     L     D     M    LS
            __  CAPS   GUI   ALT  BSPC   SPC
        """
        l2 = layer"""
        ESC     Z     D     X     L   GRV@f
        DOT     L     I  SCLN     N     F
        LCTL     R     O    LS     G     C
            B     U     N     J     Y  COMM
            __    __   GUI     K    LS     T
        """
        l3 = layer"""
        LPRN  RPRN   EQL  SLSH  ASTR  MINS
        LBRC  RBRC     1     2     3  PLUS
        LCBR  RCBR     4     5     6   ENT
        UNDS@f    __   7     8     9    LS
          __    __  COLN     0   DOT  MINS@f
        """
        l4 = layer"""
            __@f   __@f   __@f   __@f   __@f  __@f
            F1@f   F2@f   F3@f   F4@f   F5@f  F6@f
            __@f LEFT@f   UP@f DOWN@f RGHT@f DEL@f
           SFT@f HOME@f PGUP@f PGDN@f END@f PSCR@f
            __@f __@f   __@f   __@f  LS@f   __@f
        """
        lsm = LayerSwitchmap(KeyLocation(), KeyLocation(1, 3, 4), KeyLocation(1, 4, 6), KeyLocation(2, 5, 5))
    elseif template == :v0515
        l1 = layer"""
            Q    SLSH     SFT     ENT     DOT    QUOT
            TAB@f        E       H       T       I    COMM
            __       S       E      LS@f       A       W
            LS@f       N       I       V       F       K
            GUI@f    CAPS@f     ALT@f      LS@f    BSPC@f     SPC@f
            """

        l2 = layer"""
            ESC@f       Z    MINS       X       L     GRV
            SCLN       Y       B     ENT       G       T
            LCTL@f       U       O      LS@f       R       C
            S       M    Y       J       D       P
            GUI@f      __@f     ALT@f      __@f      __@f       L
        """

        l3 = layer"""
            LPRN@f  RPRN@f   EQL@f  SLSH@f  ASTR@f  MINS@f
            LBRC@f  RBRC@f     1@f     2@f     3@f  PLUS@f
            LCBR@f  RCBR@f     4@f     5@f     6@f   ENT@f
            LS@f  COMM@f     7@f     8@f     9@f  UNDS@f
            __@f    __@f  COLN@f     0@f   DOT@f   __@f
        """

        l4 = layer"""
            __    __    __    __    __    __
            F1    F2    F3    F4    F5    F6
            __  LEFT    UP  DOWN  RGHT   DEL
            SFT  HOME  PGUP  PGDN   END  PSCR
            __    __    __    LS    __    __
        """

        lsm = LayerSwitchmap(KeyLocation(), KeyLocation(1, 3, 4), KeyLocation(1, 4, 1), KeyLocation(1, 5, 4))
    
    elseif template == :v0515r3
        l1 = layer"""
            Q    SLSH     SFT     ENT     DOT    QUOT
            TAB@f        E       H       T       I    P
            COMM       S       E      LS@f       A       W
            LS@f       N       I       V       F       K
            GUI@f    CAPS@f     ALT@f      LS@f    BSPC@f     SPC@f
            """

        l2 = layer"""
            ESC@f       Z    MINS       X       L     GRV
            SCLN       Y       B     ENT       G       T
            LCTL@f       U       O      LS@f       R       C
            S       M    Y       J       D       P
            GUI@f      __@f     ALT@f      __@f      L       __
        """

        l3 = layer"""
            LPRN@f  RPRN@f   EQL@f  SLSH@f  ASTR@f  MINS@f
            LBRC@f  RBRC@f     1@f     2@f     3@f  PLUS@f
            LCBR@f  RCBR@f     4@f     5@f     6@f   ENT@f
            LS@f  COMM@f     7@f     8@f     9@f  UNDS@f
            __@f    __@f  COLN@f     0@f   DOT@f   __@f
        """

        l4 = layer"""
            __    __    __    __    __    __
            F1    F2    F3    F4    F5    F6
            __  LEFT    UP  DOWN  RGHT   DEL
            SFT  HOME  PGUP  PGDN   END  PSCR
            __    __    __    LS    __    __
        """

        lsm = LayerSwitchmap(KeyLocation(), KeyLocation(1, 3, 4), KeyLocation(1, 4, 1), KeyLocation(1, 5, 4))

    end

    lsm = LayerSwitchmap(locations(lsm)[1:3])
    push!(kmholder, l1, l2, l3)#, l4)

    # # row1 = Float32[7,   3,   1.5, 1.5, 1.5,  3.5]
    # # row2 = Float32[8,   2,   1,   1,   1,    3]
    # row1 = Float32[9,   4.5,   1.5, 1.5, 1.5,  4]
    # row2 = Float32[8,   3,   1,   1,   1,    3]
    # row3 = Float32[6,   1.5, 0.5, 0.5, 0.5,  2.5]
    # row4 = Float32[8,   4,   2.5, 3, 2.5,    4.5]
    # row5 = Float32[15,   13,   6,   3,   0.75, 0.5]

    row1 = Float32[10,  8,   2.5, 2.5, 2.5,  7]
    row2 = Float32[6,   3.5,   1,   1,   1,  4] 
    row3 = Float32[5,   1.0, 0.5, 0.5, 0.5,  3]
    row4 = Float32[7,   2.5,   1.5, 1.5, 1.5,  8]
    row5 = Float32[15,   13,   6,   3,   1.0, 0.5]

    temp = Vector{Vector{Float32}}()
    push!(temp, row1)
    push!(temp, row2)
    push!(temp, row3)
    push!(temp, row4)
    push!(temp, row5)

    el = EffortLayer(temp)

    fl = FingerMapLayer(
        [[(left, pinkie), (left, pinkie), (left, ring), (left, middle), (left, index), (left, index)],
        [(left, pinkie), (left, pinkie), (left, ring), (left, middle), (left, index), (left, index)],
        [(left, pinkie), (left, pinkie), (left, ring), (left, middle), (left, index), (left, index)],
        [(left, pinkie), (left, pinkie), (left, ring), (left, middle), (left, index), (left, index)],
        [(left, pinkie), (left, pinkie), (left, thumb), (left, thumb), (left, thumb), (left, thumb)]]
    )
    
    km = Keymap(kmholder, layerswitches=lsm, effortlayer=el, fingermaplayer=fl)

    

    # km[KeyLocation(1, 3, 5)] = Key(_LS)
    # km[KeyLocation(2, 3, 5)] = Key(_LS)
    # if numlayers == 3
    #     km[KeyLocation(1, 4, 6)] = Key(_LS)
    #     km[KeyLocation(3, 4, 6)] = Key(_LS)
    # else
    #     km[KeyLocation(1, 4, 6)] = Key(nothing, false) # layerswitch placeholder
    # end

    # km[KeyLocation(1, (2, 1))] = Key(_TAB, false)
    # km[KeyLocation(1, (3, 1))] = Key(_LCTL, false)
    # # km[KeyLocation(2, (2, 1))] = Key(_TAB, false)
    # km[KeyLocation(2, (3, 1))] = Key(_LCTL, false)

    # if !(template in v070fam)
    #     km[KeyLocation(1, 5, 4)] = Key(_ALT, false)
    #     km[KeyLocation(1, 5, 3)] = Key(_GUI, false)
    #     km[KeyLocation(2, 5, 4)] = Key(_ALT, false)
    #     km[KeyLocation(2, 5, 3)] = Key(_GUI, false)
    # end

    # km[KeyLocation(2, 1, 1)] = Key(_ESC, false)

    # km[KeyLocation(1, 5, 2)] = Key(_CAPS, false)
    # if !(template in v070fam)
    #     km[KeyLocation(1, 5, 1)] = Key(nothing, false)
    #     km[KeyLocation(2, 5, 2)] = Key(nothing, false)
    #     km[KeyLocation(2, 5, 1)] = Key(nothing, false)
    # end


    # if numlayers >= 3
    #     km[KeyLocation(3, 1, 1)] = Key(_LPRN, false)
    #     km[KeyLocation(3, 1, 2)] = Key(_RPRN, false)
    #     km[KeyLocation(3, 2, 1)] = Key(_LBRC, false)
    #     km[KeyLocation(3, 2, 2)] = Key(_RBRC, false)
    #     km[KeyLocation(3, 3, 1)] = Key(_LCBR, false)
    #     km[KeyLocation(3, 3, 2)] = Key(_RCBR, false)
    #     km[KeyLocation(3, 5, 2)] = Key(nothing, false)
    #     km[KeyLocation(3, 5, 1)] = Key(nothing, false)
        
    #     km[KeyLocation(3, 2, 3)] = Key(_1, false)
    #     km[KeyLocation(3, 2, 4)] = Key(_2, false)
    #     km[KeyLocation(3, 2, 5)] = Key(_3, false)
    #     km[KeyLocation(3, 3, 3)] = Key(_4, false)
    #     km[KeyLocation(3, 3, 4)] = Key(_5, false)
    #     km[KeyLocation(3, 3, 5)] = Key(_6, false)
    #     km[KeyLocation(3, 4, 3)] = Key(_7, false)
    #     km[KeyLocation(3, 4, 4)] = Key(_8, false)
    #     km[KeyLocation(3, 4, 5)] = Key(_9, false)
    #     km[KeyLocation(3, 5, 4)] = Key(_0, false)
    #     km[KeyLocation(3, 5, 3)] = Key(_COLN, false)
    #     km[KeyLocation(3, 5, 5)] = Key(_DOT, false)
    #     km[KeyLocation(3, 3, 6)] = Key(_ENT, false)
    #     km[KeyLocation(3, 2, 6)] = Key(_PLUS, false)
    #     km[KeyLocation(3, 1, 6)] = Key(_MINS, false)
    #     km[KeyLocation(3, 1, 5)] = Key(_ASTR, false)
    #     km[KeyLocation(3, 1, 4)] = Key(_SLSH, false)
    #     km[KL(3, 1, 3)] = Key(_EQL, false)
    #     if !(template in v070fam)
    #         km[KeyLocation(3, 4, 2)] = Key(nothing, false) # for 3rd layer shift or layer change for symbols
    #     end
    # end

    # km[KeyLocation(1, (3, 2))] = Key(_S, false)

    # println("@@@@@@@@@@@@@@@@@@@@@\nbackspace is not guaranteed to be a thumb key")
    # km[KL(1, 5, 5)] = Key(_BSPC, false)
    # km[KL(1, 5, 6)] = Key(_SPC, false)

    println("printing into stdout\n$km")
    return km

end


function gen5x7keymap(;numlayers=3, template=:default)
    @info "generating $numlayers layer version"
    kmholder = Vector{Layer{Key}}()

    if template == :default
        l1 = layer"""
            Q    SLSH     SFT     ENT     DOT    QUOT       __
            TAB@f        E       H       T       I    P     __
            COMM       S       E      LS@f       A       W  __
            LS@f       N       I       V       F       K    __
            GUI@f    CAPS@f    ALT@f      LS@f    BSPC@f     SPC@f __
            """

        l2 = layer"""
            ESC@f       Z    MINS       X       L     GRV __
            SCLN       Y       B     ENT       G       T  __
            LCTL@f       U       O      LS@f       R    C __
            S       M    Y       J       D       P        __
            GUI@f      __@f  ALT@f      __@f   __@f       L __
        """

        l3 = layer"""
            LPRN@f  RPRN@f   EQL@f  SLSH@f  ASTR@f  MINS@f __
            LBRC@f  RBRC@f     1@f     2@f     3@f  PLUS@f __
            LCBR@f  RCBR@f     4@f     5@f     6@f   ENT@f __
            LS@f  COMM@f     7@f     8@f     9@f  UNDS@f __
            __@f    __@f  COLN@f     0@f   DOT@f   __@f __
        """

        lsm = LayerSwitchmap(KeyLocation(), KeyLocation(1, 3, 4), KeyLocation(1, 4, 1), KeyLocation(1, 5, 4))
    end

    lsm = LayerSwitchmap(locations(lsm)[1:3])
    push!(kmholder, l1, l2, l3)#, l4)


    row1 = Float32[10,  8,   2.5, 2.5, 2.5,  7, 9]
    row2 = Float32[6,   3.5,   1,   1,   1,  4, 6] 
    row3 = Float32[5,   1.0, 0.5, 0.5, 0.5,  3, 5]
    row4 = Float32[7,   2.5,   1.5, 1.5, 1.5,  8, 10]
    row5 = Float32[15,   13,   6,   3,   1.0, 0.5, 2]

    temp = Vector{Vector{Float32}}()
    push!(temp, row1)
    push!(temp, row2)
    push!(temp, row3)
    push!(temp, row4)
    push!(temp, row5)

    el = EffortLayer(temp)

    fl = FingerMapLayer(
        [[(left, pinkie), (left, pinkie), (left, ring), (left, middle), (left, index), (left, index), (left, index)],
        [(left, pinkie), (left, pinkie), (left, ring), (left, middle), (left, index), (left, index), (left, index)],
        [(left, pinkie), (left, pinkie), (left, ring), (left, middle), (left, index), (left, index), (left, index)],
        [(left, pinkie), (left, pinkie), (left, ring), (left, middle), (left, index), (left, index), (left, index)],
        [(left, pinkie), (left, pinkie), (left, thumb), (left, thumb), (left, thumb), (left, thumb), (left, index)]]
    )
    
    km = Keymap(kmholder, layerswitches=lsm, effortlayer=el, fingermaplayer=fl)

    
    
    println("printing into stdout\n$km")
    return km

end



function gen4x12keymap(;numlayers=3, template=:default)
    @info "generating $numlayers layer version"
    kmholder = Vector{Layer{Key}}()

    if template == :default
        l1 = layer"""
    TAB@f    __    __    __    __    __    __    __    __    __    __    __    
    LCTL@f    __    __    __    __    __    __    __    __    __    __    ENT@f    
    __    __    __    __    __    __    __    __    __    __    __    __    
    __    __    GUI@f    ALT@f    LS    SPC@f    BSPC@f    LS    __    __    __    __    

            """

        l2 = layer"""
    ESC@f    __    __    __    __    __    __    __    __    __    __    __    
    LCTL@f __  LBRC@f  LCBR@f  LPRN@f  __  __  RPRN@f  RCBR@f  RBRC@f    __    __    
    __       __    __    __    __    __    __    __    __    __    __    __    
    __       __    __    __    LS    __    __    __    __    __    __    __    
        """

        l3 = layer"""
        __    EQL@f    1@f     2@f   3@f    PLUS@f    __    __    __    __    __    __    
        __    SLSH@f    4@f     5@f   6@f    ENT@f    __    __    __    __    __    __    
        __    ASTR@f    7@f     8@f   9@f    UNDS@f   __    __    __    __    __    __    
        __    MINS@f    COLN@f  0@f   DOT@f  __    __    LS    __    __    __    __    
        """

        lsm = LayerSwitchmap(KeyLocation(), KeyLocation(1, 4, 5), KeyLocation(1, 4, 8), KeyLocation(1, 5, 4))
    end

    lsm = LayerSwitchmap(locations(lsm)[1:3])
    push!(kmholder, l1, l2, l3)#, l4)

    row2 = Float32[6,   3.5,   1,   1,   1,  4, 4, 1, 1, 1, 3.5, 6] 
    row3 = Float32[5,   1.0, 0.5, 0.5, 0.5,  3, 3, 0.5, 0.5, 0.5, 1.0, 5.0]
    row4 = Float32[7,   2.5,   1.5, 1.5, 1.5,  8, 8, 1.5, 1.5, 1.5, 2.5, 7]
    row5 = Float32[15,   13,   6,   3,   1.0, 0.5, 0.5, 1.0, 3, 6, 13, 15]

    temp = Vector{Vector{Float32}}()

    push!(temp, row2)
    push!(temp, row3)
    push!(temp, row4)
    push!(temp, row5)

    el = EffortLayer(temp)

    fl = FingerMapLayer(
        [[(left, pinkie), (left, pinkie), (left, ring), (left, middle), (left, index), (left, index), (right, index), (right, index), (right, middle), (right, ring), (right, pinkie), (right, pinkie)],
        [(left, pinkie), (left, pinkie), (left, ring), (left, middle), (left, index), (left, index), (right, index), (right, index), (right, middle), (right, ring), (right, pinkie), (right, pinkie)],
        [(left, pinkie), (left, pinkie), (left, ring), (left, middle), (left, index), (left, index), (right, index), (right, index), (right, middle), (right, ring), (right, pinkie), (right, pinkie)],
        [(left, pinkie), (left, pinkie), (left, ring), (left, middle), (left, index), (left, index), (right, index), (right, index), (right, middle), (right, ring), (right, pinkie), (right, pinkie)]]
    )
    
    km = Keymap(kmholder, layerswitches=lsm, effortlayer=el, fingermaplayer=fl)

    km[KeyLocation(1, (3, 1))] = Key(_SFT, true, true)
    km[KeyLocation(1, (3, 12))] = Key(_SFT, true, true)

    println("printing into stdout\n$km")
    return km

end