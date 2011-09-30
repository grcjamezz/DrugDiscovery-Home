## Automatically adapted for numpy.oldnumeric Jul 23, 2007 by 


#############################################################################
#
# Author: Michel F. SANNER, Sophie COON
#
# Copyright: M. Sanner TSRI 2000
#
#############################################################################

#
# $Header: /opt/cvs/python/packages/share1.5/Pmv/colorCommands.py,v 1.128 2008/06/20 20:08:08 sargis Exp $
#
# $Id: colorCommands.py,v 1.128 2008/06/20 20:08:08 sargis Exp $
#
"""
This Module implements commands to color the current selection different ways.
for example:
    by atoms.
    by residues.
    by chains.
    etc ...
    
"""
from mglutil.util.colorUtil import ToHEX
from Pmv.colorPalette import ColorPalette, ColorPaletteFunction

import types, string, Tkinter, Pmw, os, traceback
import numpy.oldnumeric as Numeric
from ViewerFramework.VFCommand import CommandGUI
from mglutil.gui.InputForm.Tk.gui import InputFormDescr, evalString
from DejaVu.colorTool import Map, RGBARamp, RedWhiteARamp, WhiteBlueARamp,\
     RedWhiteBlueARamp
from mglutil.gui.BasicWidgets.Tk.colorWidgets import ColorChooser
from mglutil.util.callback import CallBackFunction
from Pmv.mvCommand import MVCommand, MVAtomICOM
from MolKit.tree import TreeNode, TreeNodeSet
from MolKit.molecule import Molecule, Atom, AtomSet
from MolKit.protein import Protein, Residue, Chain, ProteinSet, ChainSet, ResidueSet
from mglutil.gui.BasicWidgets.Tk.customizedWidgets import LoadOrSaveText, \
     FunctionButton, ListChooser
from mglutil.gui.BasicWidgets.Tk.colorWidgets import ColorChooser
from DejaVu.colorMap import ColorMap

class ColorCommand(MVCommand):
    """The ColorCommand class is the base class from which all the color commands implemented for PMV will derive.
    \nPackage : Pmv
    \nModule  : colorCommands
    \nClass   : ColorCommand
    \nCommand : color
    \nDescription:\n
    It implements the general functionalities to color the specified geometries
    representing the specified nodes with the given list of colors.\n
    \nSynopsis:\n
      None <--- color(nodes, colors[(1.,1.,1.),], geomsToColor='all', **kw)\n
    \nRequired Arguments:\n 
      nodes --- any set of MolKit nodes describing molecular components\n
    \nOptional Arguments:\n  
      colors --- list of rgb tuple\n
      geomsToColor --- list of the name of geometries to color default is 'all'\n
      Keywords --- color\n
    """

    def __init__(self, func=None):
        MVCommand.__init__(self, func)
        self.flag = self.flag | self.objArgOnly

    def onAddCmdToViewer(self):
        # this is done for sub classes to be able to change the undoCmdsString
        self.undoCmdsString = self.name
        
    def onRemoveObjectFromViewer(self, object):
        self.cleanup()
    
    def onAddObjectToViewer(self, object):
        self.cleanup()
        
    def doit(self, nodes, colors, geomsToColor):
        molecules, atms, nodes = self.getNodes(nodes, returnNodes=True)
        if atms is None:
            return 'ERROR'
        if len(colors)==len(nodes) and not isinstance(nodes[0], Atom):
            #expand colors from nodes to atoms
            newcolors = []
            for n,c in map(None,nodes,colors):
                newcolors.extend( [c]*len(n.findType(Atom)) )
            colors = newcolors
            
        for g in geomsToColor:
            if len(colors)==1 or len(colors)!=len(atms):
                for a in atms:
                    if not a.colors.has_key(g): continue
                    a.colors[g] = tuple( colors[0] )
            else:
                for a, c in map(None, atms, colors):
                    if not a.colors.has_key(g): continue
                    #a.colors[g] = tuple(c[:3])
                    a.colors[g] = tuple(c)

        updatedGeomsToColor = []
        for mol in molecules:
            for gName in geomsToColor:
                if not mol.geomContainer.geoms.has_key(gName): continue
                geom = mol.geomContainer.geoms[gName]
                # turn off texturemapping:
                if geom.texture is not None:
                    geom.texture.Set(enable=0, tagModified=False)
                    updatedGeomsToColor.append(gName)
                    geom.Set(inheritMaterial=0, redo=0, tagModified=False)
                    
                updatedGeomsToColor.append(gName)
                geom.Set(inheritMaterial=0, redo=0, tagModified=False)

                if geom.children != []:
                    # get geom Name:
                    childrenNames = map(lambda x: x.name, geom.children)
                    updatedGeomsToColor = updatedGeomsToColor + childrenNames
                    for childGeom in geom.children:
                        childGeom.Set(inheritMaterial=0, redo=0,
                                      tagModified=False)

            
            mol.geomContainer.updateColors(updatedGeomsToColor)

        
    def __call__(self, nodes, colors=[(1.,1.,1.),],
                 geomsToColor=('all',), **kw):
        """None <--- color(nodes, colors=[(1.,1.,1.),], geomsToColor=('all',), **kw)
        \nnodes---TreeNodeSet holding the current selection
        \ncolors---list of rgb tuple.
        \ngeomsToColor---list of the name of geometries to color,default is 'all'
        """
        if not nodes: return 'ERROR'
        
        if type(nodes) is types.StringType:
            self.nodeLogString = "'"+nodes+"'"
        nodes = self.vf.expandNodes(nodes)
        if not nodes: return 'ERROR'
        kw['redraw'] = 1
        if geomsToColor in ['all', '*'] or 'all' in geomsToColor\
           or '*' in geomsToColor:
            geomsToColor = self.getAvailableGeoms(nodes)
        if not type(geomsToColor) in [types.ListType, types.TupleType]:
            return 'ERROR'
        geomsToColor = filter(lambda x: x not in [' ', ''], geomsToColor)
        if not len(geomsToColor):
            return 'ERROR'
        status = apply( self.doitWrapper, (nodes, colors, geomsToColor), kw)
        return status


    def showForm(self, *args, **kw):
        # sub class to remove showUndis value, and force rebuilding form
        # so that list of geoms is up to date
        if args and args[0] == 'default':
            kw['force']=1
        val = MVCommand.showForm( *((self,)+args), **kw)

        try:
            del val['showUndis']
        except:
            pass
        return val
    
            
    def buildFormDescr(self, formName):
        if formName == 'default':
            idf = self.idf = InputFormDescr(title = self.name)
            geomsAvailable = self.getAvailableGeoms(self.vf.getSelection(),
                                                    showUndisplay=0)
            if geomsAvailable is None: return None

            idf.append({'widgetType':Tkinter.Button,
                        'wcfg':{'text':'All Geometries','height':2,
                                'command':self.selectall_cb},
                        'gridcfg':{'sticky':'we'}})

            idf.append({'widgetType':Tkinter.Button,
                        'wcfg':{'text':'No Geometries','height':2,
                                'command':self.deselectall_cb},
                        'gridcfg':{'row':-1,'sticky':'we'}})

            idf.append({'widgetType':Tkinter.Checkbutton,
                        'name':'showUndis',
                        'defaultValue':0,
                        'wcfg':{'text':'show undisplayed',
                                'command':self.showUndisplayed_cb,
                                'indicatoron':0,'height':2,'pady':5,'padx':5,
                                'variable':Tkinter.IntVar()},
                        'gridcfg':{'row':-1,'sticky':'we'}})

            idf.append({'widgetType':Pmw.RadioSelect,
                        'name':'geomsToColor',
                        'listtext':geomsAvailable,
                        'wcfg':{'labelpos':'n',
                                'label_text':'Select the geometry you would like to color:',
                                'orient':'vertical',
                                'buttontype':'checkbutton'},
                        'gridcfg':{'sticky':'w','columnspan':3}})
            return idf

        elif formName == 'chooseColor':
            idf = InputFormDescr(title = 'Choose Color')

            idf.append({'widgetType':ColorChooser,
                        'name':'colors',
                        'wcfg':{'title':'ColorChooser',
                                'commands':self.color_cb,
                                'immediate':0, 'exitFunction':self.dismiss_cb},
                        'gridcfg':{'sticky':'wens', 'columnspan':3}
                        })
            idf.append({'widgetType':Tkinter.Button,
                        'name':'dismiss',
                        'wcfg':{'text':'DISMISS', 'command':self.dismiss_cb},
                        'gridcfg':{'sticky':'we', 'columnspan':3}})
            
            return idf


    def guiCallback(self):
        nodes = self.vf.getSelection()
        if not nodes:
            self.warningMsg("no nodes selected")
            return 'ERROR' # to prevent logging

        val = self.showForm('default', scrolledFrame = 1,
                            width= 500, height = 200, force=1)
        if val:
            self.geomsToColor = val['geomsToColor']
        else:
            self.geomsToColor = None
            return 'ERROR'

        form = self.showForm('chooseColor', modal=0, blocking=0)


    def getNodes(self, nodes, returnNodes=False):
        """Expand nodes argument into a list of atoms and a list of
molecules.This function is used to prevent the expansion operation to be done
in both doit and setupUndoBefore.The nodes.findType( Atom ) is the operation
that is potentially expensive
"""
        if not hasattr(self, 'expandedNodes____Atoms'):
            nodes = self.vf.expandNodes(nodes)
            if nodes==self.vf.Mols:
                self.expandedNodes____Atoms = nodes.allAtoms
                self.expandedNodes____Molecules = nodes
            else:
                self.expandedNodes____Atoms = nodes.findType( Atom )
                if len(nodes) == 0:
                    self.expandedNodes____Molecules = ProteinSet()
                else:
                    self.expandedNodes____Molecules = nodes.top.uniq()
                
        if returnNodes:
            if not hasattr(self, 'expandedNodes____Nodes'):
                nodes = self.vf.expandNodes(nodes)
                self.expandedNodes____Nodes = nodes
            return self.expandedNodes____Molecules, \
                   self.expandedNodes____Atoms, self.expandedNodes____Nodes
        else:
            return self.expandedNodes____Molecules,\
                   self.expandedNodes____Atoms


    def cleanup(self):
        """ This method is called by the afterDoit method and will be called
        eventhough the doit failed.
        """
        if hasattr(self, 'expandedNodes____Molecules'):
            del self.expandedNodes____Molecules
        if hasattr(self, 'expandedNodes____Atoms'):
            del self.expandedNodes____Atoms
        if hasattr(self, 'expandedNodes____Nodes'):
            del self.expandedNodes____Nodes


    def setupUndoBefore(self, nodes, colors, geomsToColor):
        if not nodes: return 'ERROR'
        molecules, atms, nodes = self.getNodes(nodes, returnNodes=True)
        if atms is None: return 'ERROR'
        self.undoCmds = ''
        sameColor = 1

##         atmsWithGeom = []
##         for g in geomsToColor:
##             oldColors = []
##             firstCol = atms[0].colors[g]
##             for a in atms:
##                 try:
##                     col = a.colors[g]
##                 except KeyError:
##                     pass
##                 if sameColor:
##                     if col[0]!=firstCol[0] or col[1]!=firstCol[1] or \
##                        col[2]!=firstCol[2]:
##                         sameColor=0
##                 oldColors.append( col )

##             if sameColor:
##                 oldColors = firstCol

##             self.addUndoCall( (atmsWithGeom, oldColors, [g]), {'redraw':1},
##                               self.undoCmdsString )

        for g in geomsToColor:
            # all the atom don't have the entry g in their color dictionary.
            # Ca-trace, spline and secondary structure create the color
            # entry for their geometry when computed only
            atmsWithGeom = atms.get(lambda x, geom=g: x.colors.has_key(geom))

            if atmsWithGeom is None or not len(atmsWithGeom):
                continue
            
            oldColors = []
            firstCol = atmsWithGeom[0].colors[g]
            
            for a in atmsWithGeom:
                col = a.colors[g]
                if sameColor:
                    if col[0]!=firstCol[0] or col[1]!=firstCol[1] or \
                       col[2]!=firstCol[2]:
                        sameColor=0
                oldColors.append( col )

            if sameColor:
                oldColors = oldColors[:1]

            #self.addUndoCall( (atms, oldColors, [g]), {'redraw':1},
            #                  self.undoCmdsString )
            self.addUndoCall( (atmsWithGeom, oldColors, [g]), {'redraw':1},
                              self.undoCmdsString )


    def getChildrenGeomsName(self, mol):
        geomC = mol.geomContainer
        # Get the name of the geometries that are child of another one
        # We only want the parent geometry i.e. 'secondarystructure'
        # We assume that the geometry name is the same than the key in
        # the geoms dictionary.
        childGeomsName = []
        for geomName in geomC.geoms.keys():
            if geomName in ['master','selectionSpheres']:continue
            if geomC.geoms[geomName].children != []:
                names = map(lambda x: x.name,
                            geomC.geoms[geomName].children)
                childGeomsName = childGeomsName + names
        return childGeomsName


    def getAvailableGeoms(self, nodes, showUndisplay = 0):
        """Method to build a dictionary containing all the geometries
        available in the scene."""
        # if no nodes specified no geometries.
        if not nodes:
            return
        molecules, atms = self.getNodes(nodes)
        geomsAvailable = []
        for mol in molecules:
          #if hasattr(mol,"geomContainer"):
            geomC = mol.geomContainer
            childGeomsName = self.getChildrenGeomsName(mol)
            
            # We only put the one we are ineterested in in the list
            # of geomsAvailable 
            for geomName in geomC.geoms.keys():
                if geomName in ['master','selectionSpheres'] :
                    continue
                if geomC.atoms.has_key(geomName):
                    if geomName in childGeomsName and geomC.geoms[geomName].children==[]:
                        continue
                    childgnames=[]
                    if geomC.geoms[geomName].children != []:
                        childnames = map(lambda x: x.name,geomC.geoms[geomName].children)
                        childgnames=childgnames+childnames
                        
                        for child in childgnames:
                            if geomC.atoms[geomName]==[] and geomC.atoms[child]!=[]:
                                if not geomName in geomsAvailable:
                                    geomsAvailable.append(geomName)
                    else:   
                        if geomC.atoms[geomName]!=[]:
                           if not geomName in geomsAvailable:
                                geomsAvailable.append(geomName) 
                        
                        
        return geomsAvailable   
        

    def selectall_cb(self):
        radioselect = self.idf.entryByName['geomsToColor']['widget']
        geoms = radioselect._buttonList
        selectedgeoms = radioselect.getcurselection()
        for g in geoms:
            if not g in selectedgeoms:
                radioselect.invoke(g)

          
    def deselectall_cb(self):
        radioselect = self.idf.entryByName['geomsToColor']['widget']
        geoms = radioselect._buttonList
        selectedgeoms = radioselect.getcurselection()
        for g in geoms:
            if g in selectedgeoms:
                radioselect.invoke(g)


    def showUndisplayed_cb(self):
        entries = self.idf.entryByName
        showUndisplay = entries['showUndis']['wcfg']['variable'].get()
        widget = entries['geomsToColor']['widget']
        if showUndisplay == 1:
            self.addNewEntries(widget,showUndisplay)
        elif showUndisplay == 0:
            self.addNewEntries(widget,showUndisplay)


    def addNewEntries(self, widget, showUndisplay):
        widget.deleteall()
        nodes = self.vf.getSelection()
        geomsAvailable = self.getAvailableGeoms(nodes = nodes,
                                                showUndisplay=showUndisplay)
        for g in geomsAvailable:
            widget.add(g)


    def dismiss_cb(self):
        if self.cmdForms.has_key('chooseColor'):
            self.cmdForms['chooseColor'].withdraw()
            
    def color_cb(self, colors):
        self.doitWrapper(self.vf.getSelection(), [colors,],
                         self.geomsToColor, redraw=1)


colorGuiDescr = {'widgetType':'Menu', 'menuBarName':'menuRoot',
                 'menuButtonName':'Color', 'menuEntryLabel':'Choose Color'}

ColorGUI = CommandGUI()
ColorGUI.addMenuCommand('menuRoot', 'Color', 'Choose Color')


class ColorFromPalette(ColorCommand, MVAtomICOM):
    """The ColorFromPalette class is the base class from which all the color commands using a colorPalette implemented for PMV will derive.
    \nPackage : Pmv
    \nModule  : colorCommands
    \nClass   : ColorFromPalette
    \nDescription:\n
     It implements the general functionalities needed to retrieve the colors given a palette and a set of nodes.\n
    \nSynopsis:\n
     None <- colorFromPalette(nodes, geomsToColor='all')\n
     \nRequired Arguments:\n      
     nodes---TreeNodeSet holding the current selection\n
     geomsToColor---list of the name of geometries to color,default is 'all\n
    
    """
    # THE USER SHOULD BE ABLE TO CREATE A COLORPALETTE AND USE IT TO COLOR THE
    # SELECTED NODES WITH IT.
    
    def __init__(self, func=None):
        ColorCommand.__init__(self, func)
        MVAtomICOM.__init__(self)
        self.flag = self.flag | self.objArgOnly
        from mglutil.util.defaultPalettes import ChooseColor, \
             ChooseColorSortedKeys

        c = 'Color palette'
        self.palette = ColorPalette('Color palette', ChooseColor,
                                    readonly=0, info=c,
                                    sortedkeys=ChooseColorSortedKeys )
    
    def setupUndoBefore(self, nodes, geomsToColor):
        # these commands do not require the color argument since colors are
        # gotten from a palette
        # we still can use the ColorCommand.setupUndoBefore method by simply
        # passing None for the color argument
        ColorCommand.setupUndoBefore(self, nodes, None, geomsToColor)
        

    def doit(self, nodes, geomsToColor):
        # these commands do not require the color argument since colors are
        # gotten from a palette
        # we still can use the ColorCommand.setupUndoBefore but first we get
        # the colors. This also insures that the colors are not put inside the
        # log string for these commands
        molecules, nodes = self.getNodes(nodes)
        if nodes is None:
            return 'ERROR'
        colors = self.getColors(nodes)
        ColorCommand.doit(self, nodes, colors, geomsToColor)

            
    def onAddCmdToViewer(self):
        # these commands use a color command to undo their effect
        # so we make sure it is loaded and we place its name into
        # undoCmdsString
        if not self.vf.commands.has_key('color'):
            self.vf.loadCommand('colorCommands', 'color', 'Pmv',
                                topCommand=0)
        self.undoCmdsString= self.vf.color.name
        
        
    def getColors(self, nodes):
        return self.palette.lookup( nodes )


    def guiCallback(self):
        nodes = self.vf.getSelection()
        if not nodes:
            return 'Error' # to prevent logging
        val = self.showForm('default', scrolledFrame = 1,
                            width= 500, height = 200, force=1)
        if val:
            geomsToColor = val['geomsToColor']
        else:
            geomsToColor = None
##             self.warningMsg("ERROR: No geometry to color")
            return

        self.doitWrapper(nodes, geomsToColor, redraw=1)


    def __call__(self, nodes, geomsToColor='all', **kw):
        """None <- colorFromPalette(nodes, geomsToColor='all', **kw)
           \nnodes --- TreeNodeSet holding the current selection
           \ngeomsToColor --- list of the name of geometries to color,
                         default is 'all'"""
        if type(nodes) is types.StringType:
            self.nodeLogString = "'"+nodes+"'"

        nodes = self.vf.expandNodes(nodes)
        if not nodes:
            return 'ERROR'
        geomsToColor = filter(lambda x: x not in [' ', ''], geomsToColor)
        if not len(geomsToColor):
            return 'ERROR'
        if geomsToColor in ['all', '*'] or 'all' in geomsToColor\
           or '*' in geomsToColor:
            geomsToColor = self.getAvailableGeoms(nodes)

        if not len(geomsToColor):
            self.cleanup()
            return 'ERROR'

        if not kw.has_key('redraw'): kw['redraw'] = 1
        status = apply( self.doitWrapper, (nodes, geomsToColor), kw)
        return status


class ColorByAtomType(ColorFromPalette):
    """The colorByAtomType command allows the user to color the given geometry representing the given nodes using the atomtype coloring scheme where:N :Blue ; C : White ; O : Red ; S : Yellow ; H : Cyan; P: Magenta;UNK:green.
    \nPackage : Pmv
    \nModule  : colorCommands
    \nClass   :  ColorByAtomType
    \nCommand : colorbyAtomType
    \nDescription:\n
    This coloring scheme gives some information on the atomic composition of
    the given nodes.\n
    \nSynopsis:\n
    None <- colorByAtomType(nodes, geomsToColor='all', **kw)\n
    nodes       : any set of MolKit nodes describing molecular components\n
    geomsToColor: list of the name of geometries to color default is 'all'\n
    Keywords: color, atom type\n
    """
    def __init__(self, func=None):
        ColorFromPalette.__init__(self, func=func)
        from Pmv.pmvPalettes import AtomElements
        c = 'Color palette for atom type'
        self.palette = ColorPalette('AtomElements', colorDict=AtomElements,
                                    readonly=0, info=c,
                                    lookupMember='element')

colorByAtomTypeGuiDescr = {'widgetType':'Menu', 'menuBarName':'menuRoot',
                           'menuButtonName':'Color',
                           'menuEntryLabel':'by Atom Type'}

ColorByAtomTypeGUI = CommandGUI()
ColorByAtomTypeGUI.addMenuCommand('menuRoot', 'Color', 'by Atom Type')



class ColorByDG(ColorFromPalette):
    """The colorByDG command allows the user to color the given geometries representing the given nodes using the following David Goodsell coloring
    scheme.
    \nPackage : Pmv
    \nModule  : colorCommands
    \nClass   : ColorByDG
    \nCommand : colorByDG
    \nSynopsis:\n
    None <--- colorByDG(nodes, geomsToColor='all', **kw)\n
    \nArguments:\n
    nodes --- any set of MolKit nodes describing molecular components\n
    geomsToColor --- list of the name of geometries to color default is 'all'\n
    Keywords --- color, David Goodsell coloring scheme\n
    """
    
    def __init__(self, func=None):
        ColorFromPalette.__init__(self, func=func)
        from Pmv.pmvPalettes import DavidGoodsell, DavidGoodsellSortedKeys
        c = 'Color palette for coloring using David Goodsells colors'
        self.palette = ColorPaletteFunction('DavidGoodsell',
                                            DavidGoodsell, readonly=0,
                                            info=c,
                                            sortedkeys=DavidGoodsellSortedKeys,
                                            lookupFunction=self.lookupFunc)

        self.DGatomIds=['ASPOD1','ASPOD2','GLUOE1','GLUOE2', 'SERHG',
                        'THRHG1','TYROH','TYRHH',
                        'LYSNZ','LYSHZ1','LYSHZ2','LYSHZ3','ARGNE','ARGNH1','ARGNH2',
                        'ARGHH11','ARGHH12','ARGHH21','ARGHH22','ARGHE','GLNHE21',
                        'GLNHE22','GLNHE2',
                        'ASNHD2','ASNHD21', 'ASNHD22','HISHD1','HISHE2' ,
                        'CYSHG', 'HN']
        
    def lookupFunc(self, atom):
        assert isinstance(atom, Atom)
        if atom.name in ['HN']:
            atom.atomId = atom.name
        else:
            atom.atomId=atom.parent.type+atom.name
        if atom.atomId not in self.DGatomIds: 
            atom.atomId=atom.element
        return atom.atomId


colorByDGGuiDescr = {'widgetType':'Menu', 'menuBarName':'menuRoot',
                     'menuButtonName':'Color', 'menuEntryLabel':'by DG colors'}

ColorByDGGUI= CommandGUI()
ColorByDGGUI.addMenuCommand('menuRoot', 'Color', 'by DG colors')



class ColorByResidueType(ColorFromPalette):
    """The colorByResidueType command allows the user to color the given geometries representing the given nodes using the Rasmol coloring scheme.
    \nPackage : Pmv
    \nModule  : colorCommands
    \nClass   : ColorByResidueType
    \nCommand : colorByResidueType
    \nwhere:\n
    ASP, GLU    bright red       CYS, MET       yellow\n
    LYS, ARG    blue             SER, THR       orange\n
    PHE, TYR    mid blue         ASN, GLN       cyan\n
    GLY         light grey       LEU, VAL, ILE  green\n
    ALA         dark grey        TRP            pink\n
    HIS         pale blue        PRO            flesh\n
    \nSynopsis:\n
      None <- colorByResidueType(nodes, geomsToColor='all', **kw)\n
      nodes --- any set of MolKit nodes describing molecular components.\n
      geomsToColor --- list of the name of geometries to color default is 'all'\n
    Keywords --- color, Rasmol, residue type\n
    """
    
    def __init__(self, func=None):
        ColorFromPalette.__init__(self, func=func)
        from Pmv.pmvPalettes import RasmolAmino, RasmolAminoSortedKeys
        c = 'Color palette for Rasmol like residues types'
        self.palette = ColorPalette('RasmolAmino', RasmolAmino, readonly=0,
                                    info=c,
                                    sortedkeys = RasmolAminoSortedKeys,
                                    lookupMember='type')


    def getColors(self, nodes):
        return self.palette.lookup( nodes.findType(Residue) )

colorByResdueTypeGuiDescr = {'widgetType':'Menu', 'menuBarName':'menuRoot',
                             'menuButtonName':'Color',
                             'menuEntryLabel':'RasmolAmino',
                             'menuCascadeName':'by Residue Type'}

ColorByResidueTypeGUI = CommandGUI()
ColorByResidueTypeGUI.addMenuCommand('menuRoot', 'Color', 'RasmolAmino',
                     cascadeName = 'by Residue Type')



class ColorShapely(ColorFromPalette):
    """The colorByShapely command allows the user to color the given geometries representing the given nodes using the Shapely coloring scheme where each residue has a different color. (For more information please refer to the pmv tutorial).
    \nPackage : Pmv
    \nModule  : colorCommands
    \nClass   : ColorByResidueType
    \nCommand : colorByResidueType
    \nSynopsis:\n
      None <- colorByShapely(nodes, geomsToColor='all', **kw)\n
      nodes --- any set of MolKit nodes describing molecular components\n
      geomsToColor --- list of the name of geometries to color default is 'all'\n
      Keywords --- color, shapely, residue type\n
    """
    def __init__(self, func=None):
        ColorFromPalette.__init__(self, func=func)
        from Pmv.pmvPalettes import Shapely
        c = 'Color palette for shapely residues types'
        self.palette = ColorPalette('Shapely', Shapely, readonly=0, info=c,
                               lookupMember='type')
    

    def getColors(self, nodes):
        if not nodes: return "ERROR"
        return self.palette.lookup( nodes.findType(Residue) )

colorShapelyGuiDescr = {'widgetType':'Menu', 'menuBarName':'menuRoot',
                        'menuButtonName':'Color', 'menuEntryLabel':'Shapely',
                        'menuCascadeName':'by Residue Type'}

ColorShapelyGUI = CommandGUI()
ColorShapelyGUI.addMenuCommand('menuRoot', 'Color', 'Shapely',
                     cascadeName = 'by Residue Type')

##
## FIXME ramp should be a colorMap object with editor and stuff
## it should be possible to pass it as an argument. if none is given a default
## a colorMap object with a default RGBRamp would be used
## This is also true for Palettes.
##
from DejaVu.colorTool import Map

class ColorFromRamp(ColorFromPalette):
    """The colorFromRamp class implements the functionality to color the given geometries representing the given nodes using a colorMap created from the Ramp.
    \nPackage : Pmv
    \nModule  : colorCommands
    \nClass   : ColorFromRamp
    \nSynopsis:\n
      None <- colorFromRamp(nodes, geomsToColor='all', **kw)\n
      nodes --- any set of MolKit nodes describing molecular components\n
      geomsToColor --- list of the name of geometries to color default is 'all'\n
      Keywords --- color, ramp\n
    """
 
    def __init__(self):
        ColorFromPalette.__init__(self)
        self.flag = self.flag | self.objArgOnly
        from DejaVu.colorTool import RGBRamp, Map
        self.ramp = RGBRamp()

class ColorByChain(ColorFromPalette):
    """The colorByChain command allows the user to color the given geometries representing the given nodes by chain. A different color is assigned to each chain.
    \nPackage : Pmv
    \nModule  : colorCommands
    \nClass   : ColorByChain
    \nCommand : colorByChain
    \nSynopsis:\n
      None <- colorByChain(nodes, geomsToColor='all', **kw)\n
      nodes --- any set of MolKit nodes describing molecular components\n
      geomsToColor --- list of the name of geometries to color default is 'all'\n
      Keywords --- color, chain\n
    """
 
    def __init__(self, func=None):
        ColorFromPalette.__init__(self, func=func)
        from mglutil.util.defaultPalettes import Rainbow, RainbowSortedKey
        c = 'Color palette chain number'
        
        self.palette = ColorPaletteFunction('Rainbow', Rainbow, readonly=0,
                                            info=c,
                                            lookupFunction = lambda x,
                                            length = len(RainbowSortedKey):\
                                            x.number%length,
                                            sortedkeys = RainbowSortedKey)

    def onAddObjectToViewer(self, obj):
        for c in obj.chains:
            c.number = self.vf.Mols.chains.index(c)
        if not self.vf.commands.has_key('color'):
            self.vf.loadCommand('colorCommands', 'color', 'Pmv',
                                topCommand=0)
        self.undoCmdsString= self.vf.color.name
        self.cleanup()
        
    def getColors(self, nodes):
        colors = self.palette.lookup(nodes.findType(Chain))
        return colors

colorByChainGuiDescr = {'widgetType':'Menu', 'menuBarName':'menuRoot',
                        'menuButtonName':'Color', 'menuEntryLabel':'by Chain'}

ColorByChainGUI = CommandGUI()
ColorByChainGUI.addMenuCommand('menuRoot', 'Color', 'by Chain')

class ColorByMolecule(ColorFromPalette):
    """The colorByChain command allows the user to color the given geometries representing the given nodes by molecules. A different color is assigned to each molecule.
    \nPackage : Pmv
    \nModule  : colorCommands
    \nClass   : ColorByChain
    \nCommand : colorByChain
    \nSynopsis:\n
      None <- colorByMolecule(nodes, geomsToColor='all', **kw)\n
      nodes --- any set of MolKit nodes describing molecular components\n
      geomsToColor --- list of the name of geometries to color default is 'all'\n
      Keywords --- color, chain\n
    """
    def __init__(self, func=None):
        ColorFromPalette.__init__(self, func=func)
        from mglutil.util.defaultPalettes import Rainbow, RainbowSortedKey
        c = 'Color palette molecule number'
        self.palette = ColorPaletteFunction(
            'Rainbow', Rainbow, readonly=0, info=c,
            lookupFunction = lambda x, length=len(RainbowSortedKey): \
            x.number%length, sortedkeys=RainbowSortedKey)

    def onAddObjectToViewer(self, obj):
        obj.number = self.vf.Mols.index(obj)
        if not self.vf.commands.has_key('color'):
            self.vf.loadCommand('colorCommands', 'color', 'Pmv',
                                topCommand=0)
        self.undoCmdsString= self.vf.color.name
        self.cleanup()
        
    def getColors(self, nodes):
        if not nodes: return
        colors = self.palette.lookup(nodes.top)
        return colors

colorByMoleculeGuiDescr = {'widgetType':'Menu', 'menuBarName':'menuRoot',
                           'menuButtonName':'Color',
                           'menuEntryLabel':'by Molecules'}

ColorByMoleculeGUI = CommandGUI()
ColorByMoleculeGUI.addMenuCommand('menuRoot', 'Color', 'by Molecules')


class ColorByInstance(ColorFromPalette):
    """Command to color the current selection by instance using a Rainbow palette.
    \nPackage : Pmv
    \nModule  : colorCommands
    \nClass   : ColorByInstance
    \nCommand : colorByInstance
    \nSynopsis:\n
      None <- colorByInstance(nodes, geomsToColor='all', **kw)\n
      nodes --- any set of MolKit nodes describing molecular components\n
      geomsToColor --- list of the name of geometries to color default is 'all'\n
    """
    def __init__(self, func=None):
        ColorFromPalette.__init__(self, func=func)
        from mglutil.util.defaultPalettes import Rainbow, RainbowSortedKey
        c = 'Color palette molecule number'
        self.palette = ColorPaletteFunction(
            'Rainbow', Rainbow, readonly=0, info=c,
            lookupFunction = lambda x, length=len(RainbowSortedKey): \
            x%length, sortedkeys=RainbowSortedKey)


    def onAddObjectToViewer(self, obj):
        obj.number = self.vf.Mols.index(obj)
        if not self.vf.commands.has_key('color'):
            self.vf.loadCommand('colorCommands', 'color', 'Pmv',
                                topCommand=0)
        self.undoCmdsString= self.vf.color.name
        self.cleanup()


    def doit(self, nodes, geomsToColor):
        molecules, nodes = self.getNodes(nodes)
        if nodes is None :
            return 'ERROR'
        for m in molecules:
            geomc = m.geomContainer
            for g in geomsToColor:
                ge = geomc.geoms[g]
                colors = self.palette.lookup(range(len(ge.instanceMatrices)))
                ge.Set(materials=colors, inheritMaterial=0, tagModified=False)
                ge.SetForChildren(inheritMaterial=True, recursive=True)
#                ColorCommand.doit(self, m, colors, geomsToColor)


colorByInstanceGuiDescr = {'widgetType':'Menu', 'menuBarName':'menuRoot',
                           'menuButtonName':'Color',
                           'menuEntryLabel':'by Instance'}

ColorByInstanceGUI = CommandGUI()
ColorByInstanceGUI.addMenuCommand('menuRoot', 'Color', 'by Instance')


class ColorByProperties(ColorCommand):
    """
    Command to color the current selection according to the integer
    or float properties, or by defining a function.
    \nPackage : Pmv
    \nModule  : colorCommands
    \nClass   : ColorByProperties
    \nCommand : colorByProperties
    \nSynopsis:\n
      None <- colorByProperties(nodes, geomsToColor, property,colormap='rgb256', **kw)\n
      nodes --- any set of MolKit nodes describing molecular components\n
      geomsToColor --- list of the name of geometries to color default is 'all'\n
      property ---  property name of type integer or float or property defined by a function returning a list of float or int.\n
      colormap ---  either a string representing a colormap or a DejaVu.ColorMap instance.\n
    """

    levelOrder = {'Atom':0 , 
                  'Residue':1,
                  'Chain':2,
                  'Molecule':3 }

    def __init__(self, func=None):
        ColorCommand.__init__(self, func)
        self.flag = self.flag & 0
        self.level = None  # class at this level (i.e. Molecule, Residue, Atom)


    def onAddCmdToViewer(self):
        # Load the color maps commands
        if not self.vf.commands.has_key('loadColorMap'):
            self.vf.loadCommand("dejaVuCommands",'loadColorMap',
                                'ViewerFramework', log=0)
        if not self.vf.commands.has_key('editColorMap'):
            self.vf.loadCommand("dejaVuCommands","editColorMap",
                                "ViewerFramework", log=0)
        
        if not self.vf.commands.has_key('showCMGUI'):
            self.vf.loadCommand("dejaVuCommands","showCMGUI",
                                "ViewerFramework", log=0)
        
        if not self.vf.commands.has_key('editColorMap'):
            self.vf.loadCommand("dejaVuCommands","editColorMap",
                                "ViewerFramework")

        # these commands use a color command to undo their effect
        # so we make sure it is loaded and we place its name into
        # undoCmdsString
        if not self.vf.commands.has_key('color'):
            self.vf.loadCommand('colorCommands', 'color', 'Pmv',
                                topCommand=0)
        self.undoCmdsString = self.vf.color.name
        from MolKit.molecule import Molecule, Atom
        from MolKit.protein import Protein, Residue, Chain
        self.molDict = {'Molecule':Molecule,
                        'Atom':Atom, 'Residue':Residue, 'Chain':Chain}
        self.nameDict = {Molecule:'Molecule', Atom:'Atom', Residue:'Residue',
                         Chain:'Chain'}

        self.leveloption={}
        for name in ['Atom', 'Residue', 'Molecule', 'Chain']:
            col = self.vf.ICmdCaller.levelColors[name]
            bg = ToHEX((col[0]/1.5,col[1]/1.5,col[2]/1.5))
            ag = ToHEX(col)
            self.leveloption[name]={'bg':bg,'activebackground':ag,
                                    'borderwidth':3}
        self.propValues = None
        self.getVal = 0
        self.level = self.nameDict[self.vf.selectionLevel]
        self.propertyLevel = self.level


    def updateLevel_cb(self, tag):
        #if tag != self.level:
        #    self.level = tag
        if tag != self.propertyLevel:
            self.propertyLevel = tag
            
        #if self.molDict[tag]  != self.vf.ICmdCaller.level.value:
            #self.vf.setIcomLevel(self.molDict[tag])
            #force a change of selection level too in order to get
            #list of properties at 'tat' level
            #self.vf.setSelectionLevel(self.molDict[tag])

            lSelection = self.vf.getSelection().uniq().findType(
                self.molDict[tag]).uniq()
            lSelection.sort()
            self.updateChooser(lSelection)
            self.cleanup()


    def getPropValues(self, nodes, prop, propertyLevel=None):
        #print "getPropValues", self, nodes, prop, propertyLevel
        #import pdb;pdb.set_trace()
        try:
            if propertyLevel is not None:
                #lNodesInLevel = self.vf.getSelection().findType(self.molDict[propertyLevel])
                lNodesInLevel = nodes.findType(self.molDict[propertyLevel])
                self.propValues = getattr(lNodesInLevel, prop)
            else:
                self.propValues = getattr(nodes, prop)
        except:
            msg= "Some nodes do not have the selected property, therefore the \
current selection cannot be colored using this function."
            self.warningMsg(msg)
            self.propValues=None


    def loadCM_cb(self, event=None):
        """ Callback to load a new color map file."""
        filename = self.vf.askFileOpen(types=[('color map files:',
                                               '*_map.py'),
                                              ('all files:', '*')],
                                       title = 'Color Map File:')
        if not filename: return
        cm = self.vf.loadColorMap(filename)
        # then need to update the combobox
        ebn = self.cmdForms['byProp'].descr.entryByName
        # get a handle on the combobox with the colormaps
        cbb = ebn['colormap']['widget']
        # save the one selected.
        selcm = cbb.get()
        cbb.clear()
        cbb._list.setlist(self.vf.colorMaps.keys())
        cbb.selectitem(selcm)


    def updateCM(self, event=None):
        ebn = self.cmdForms['byProp'].descr.entryByName
        mini = ebn['valMin']['widget'].get()
        maxi = ebn['valMax']['widget'].get()
        ebn["cmMin"]['widget'].setentry(mini)
        ebn['cmMax']['widget'].setentry(maxi)


    def updateMiniMaxi(self, cmName, event=None):
        # get the colorMap
        cm = self.vf.colorMaps[cmName]
        mini = cm.mini
        maxi = cm.maxi
        ebn = self.cmdForms['byProp'].descr.entryByName
        if mini is not None:
            ebn["cmMin"]['widget'].setentry(mini)
        if maxi is not None:
            ebn['cmMax']['widget'].setentry(maxi)


    def updateValMinMax(self, event=None):
        #print "updateValMinMax"
        ebn = self.cmdForms['byProp'].descr.entryByName
        widget = ebn['properties']['widget']
        properties = widget.get()
        if len(properties)==0:
            self.propValues=None
        else:
            self.getPropValues(self.selection, properties[0], self.propertyLevel)
        minEntry = ebn['valMin']['widget']
        maxEntry = ebn['valMax']['widget']
        self.getVal = 1
        if self.propValues is None :
            mini = 0
            maxi = 0
        else:
            mini = min(self.propValues)
            maxi = max(self.propValues)
        minEntry.setentry(mini)
        maxEntry.setentry(maxi)


    def entryValidate(self, text):
        if not text in self.vf.colorMaps.keys():
            return Pmw.PARTIAL
        else:
            return 1


    def buildFormDescr(self, formName):
        if formName == 'default':
            idf = ColorCommand.buildFormDescr(self, formName)
            return idf
        
        elif formName == 'byProp':
            idf = InputFormDescr(title = 'Color by properties')
            if len(self.properties)>0 :
                #val = self.nameDict[self.vf.ICmdCaller.level.value]
                val = self.level
                listoption = {'Atom':{'bg':'yellow',
                                      'activebackground':'yellow',
                                      'borderwidth':3},
                              'Residue':{'bg':'green',
                                         'activebackground':'green',
                                         'borderwidth':3},
                              'Chain':{'bg':'cyan',
                                       'activebackground':'cyan',
                                       'borderwidth':3},
                              'Molecule':{'bg':'red',
                                          'activebackground':'red',
                                          'borderwidth':3}
                              }
                
                idf.append({'widgetType':Pmw.RadioSelect,
                            'name':'level',
                            'listtext':['Atom', 'Residue', 'Chain','Molecule'],
                            'defaultValue':val,'listoption':self.leveloption,
                            'wcfg':{'label_text':'Change the property level:',
                                    'labelpos':'nw',
                                    'command':self.updateLevel_cb,
                                    },
                            'gridcfg':{'sticky':'we','columnspan':2}})

                propertyNames = map(lambda x: (x[0],None), self.properties)
                propertyNames.sort()
                idf.append({'name':'properties',
                            'widgetType':ListChooser,
                            'required':1,
                            'wcfg':{'entries': propertyNames,
                                    'title':'Choose one or more properties:',
                                    'lbwcfg':{'exportselection':0},
                                    'mode':'single','withComment':0,
                                    'command':self.updateValMinMax
                                    
                                    },
                            'gridcfg':{'sticky':'we', 'rowspan':4, 'padx':5}})
                #### COLORMAP
                idf.append({'name':'cmGroup',
                            'widgetType':Pmw.Group,
                            'container':{'cmGroup':"w.interior()"},
                            'wcfg':{'tag_text':"Color Map:"},
                        'gridcfg':{'sticky':'wnse'}})
                # Edit map
                idf.append({'name':'editmap',
                            'parent':'cmGroup',
                            'widgetType':Tkinter.Checkbutton,
                            'wcfg':{'text':'Edit',
                                    'variable':Tkinter.IntVar()},
                            'gridcfg':{'sticky':'we'}})

                cmNames = self.vf.colorMaps.keys()
                if len(cmNames): 
                    idf.append({'name':'colormap',
                                'parent':'cmGroup',
                                'widgetType':Pmw.ComboBox,
                                'defaultValue':cmNames[0],
                                'required':1,
                                'tooltip':"Choose a colormap from the list \
below.",
                                'wcfg':{
                        'entryfield_validate':self.entryValidate,
                        'scrolledlist_items':cmNames,
                        'history':0,
                        'selectioncommand':self.updateMiniMaxi},
                                'gridcfg':{'row':-1,'sticky':'we', 'padx':10}})
                else:
                    idf.append({'name':'colormap',
                                'parent':'cmGroup',
                                'widgetType':Pmw.ComboBox,
                                'required':1,
                                'tooltip':"Choose a colormap from the list \
below.",
                                'wcfg':{
                        'entryfield_validate':self.entryValidate,
                        'scrolledlist_items':cmNames,
                        'history':0,
                        'selectioncommand':self.updateMiniMaxi},
                                'gridcfg':{'row':-1,'sticky':'we', 'padx':10}})
                    
#                idf.append({'name':'loadCM',
#                            'parent':'cmGroup',
#                            'widgetType':Tkinter.Button,
#                            'tooltip':"Load a new color map",
#                            'wcfg':{'text':'Load color map',
#                                    'command':self.loadCM_cb,
#                                    },
#                            'gridcfg':{'row':-1}})

                idf.append({'name':'minMax',
                            'widgetType':Pmw.Group,
                            'parent':'cmdGroup',
                            'container':{"minMax":"w.interior()"},
                            'gridcfg':{'sticky':'wnse'}})

                idf.append({'name':'valueMiniMaxi',
                            'widgetType':Pmw.Group,
                            'parent':'minMax',
                            'container':{"valminimaxi":'w.interior()'},
                            'wcfg':{'tag_text':"Property Values:"},
                            'gridcfg':{'sticky':'wnse'}})


                idf.append({'name':'updateCM',
                            'parent':'minMax',
                            'widgetType':Tkinter.Button,
                            'tooltip':"Update the ColorMap mini and maxi values \n with the property values mini\
 and maxi",
                            'wcfg':{'text':">>", 'command':self.updateCM},
                            'gridcfg':{'row':-1}
                            })


                idf.append({'name':'cmninmaxi',
                            'widgetType':Pmw.Group,
                            'parent':'minMax',
                            'container':{"cmminimaxi":'w.interior()'},
                            'wcfg':{'tag_text':"ColorMap:"},
                            'gridcfg':{'sticky':'wnse', 'row':-1}})

                idf.append({'name':"valMin",
                            'widgetType':Pmw.EntryField,
                            'parent':'valminimaxi',
                            'wcfg':{'label_text':'Minimum',
                                    'labelpos':'w'},
                            })
                idf.append({'name':"valMax",
                            'widgetType':Pmw.EntryField,
                            'parent':'valminimaxi',
                            'wcfg':{'label_text':'Maximum',
                                    'labelpos':'w'},
                            })
                
                if len(cmNames):
                    cmMin = self.vf.colorMaps[cmNames[0]].mini
                    cmMax = self.vf.colorMaps[cmNames[0]].maxi
                if len(cmNames) and cmMin is not None and cmMax is not None:
                    idf.append({'name':"cmMin",
                                'widgetType':Pmw.EntryField,
                                'parent':'cmminimaxi',
                                'wcfg':{'label_text':'Minimum',
                                        'labelpos':'w',
                                        'value':cmMin},
                                'gridcfg':{}
                                })
                    idf.append({'name':"cmMax",
                                'widgetType':Pmw.EntryField,
                                'parent':'cmminimaxi',
                                'wcfg':{'label_text':'Maximum',
                                        'value':cmMax,
                                        'labelpos':'w'},
                                })
                else:
                    idf.append({'name':"cmMin",
                                'widgetType':Pmw.EntryField,
                                'parent':'cmminimaxi',
                                'wcfg':{'label_text':'Minimum',
                                        'labelpos':'w'},
                                'gridcfg':{}
                                })

                    idf.append({'name':"cmMax",
                                'widgetType':Pmw.EntryField,
                                'parent':'cmminimaxi',
                                'wcfg':{'label_text':'Maximum',
                                        'labelpos':'w'},
                                })
                return idf


    def updateChooser(self, selection):
        if not hasattr(self, 'properties'): self.properties = []
        oldProp = self.properties
        self.properties = filter(lambda x: isinstance(x[1], types.IntType) \
                                 or isinstance(x[1], types.FloatType),
                                 selection[0].__dict__.items())

        # Filter out the private members starting by __.
        self.properties = filter(lambda x: x[0][:2]!='__', self.properties)
        
        if self.cmdForms.has_key('byProp'):
            # If the list of properties changed then need to update the listbox
            ebn = self.cmdForms['byProp'].descr.entryByName
            widget = ebn['properties']['widget']
            propertyNames = map(lambda x: (x[0],None), self.properties)
            propertyNames.sort()
            oldsel = widget.get()
            widget.setlist(propertyNames)
            if len(oldsel)>0 and (oldsel[0], None) in propertyNames:
                widget.set(oldsel[0])


    def guiCallback(self):
        # return is no molecule loaded:

        # FIXME we should not expand to the selection level here
        self.selection = self.vf.getSelection().findType(self.vf.selectionLevel)
        if not self.selection: return 'ERROR' # to prevent logging
        self.level = self.nameDict[self.vf.selectionLevel]
        self.selection.sort()
        # Get the geometry to color
        val = self.showForm('default', scrolledFrame = 1,
                            width= 500, height = 200, force=1)
        if val:
            geomsToColor = val['geomsToColor']
        else:
            geomsToColor = None
            return 'ERROR'
        
        self.updateChooser(self.selection)
        # Update the inputForm if it exists:
        if self.cmdForms.has_key('byProp'):
            # Check if the level is the same than the one on the menu bar
            ebn = self.cmdForms['byProp'].descr.entryByName
            levelwid = ebn['level']['widget']
            oldlevel = levelwid.getcurselection()
            #if oldlevel != self.nameDict[self.vf.ICmdCaller.level.value]:
            #    levelwid.invoke(self.nameDict[self.vf.ICmdCaller.level.value])
            if oldlevel != self.level:
                #print 'calling levelwid.invoke with ', self.level
                levelwid.invoke(self.level)
            # Update the colormaps combobox
            cbb = ebn['colormap']['widget']
            cbb.clear()
            cms = self.vf.colorMaps.keys()
            cbb._list.setlist(cms)
            cbb.selectitem(cms[0])
            self.updateValMinMax()

        # Call showForm
        val = self.showForm('byProp')
        if val=={} or not val['properties']: return
        val['colormap'] = val['colormap'][0]
        property = val['properties'][0]
        del val['properties']
        try:
            mini = float(val['cmMin'])
            val['mini'] = mini
        except:
            mini = None
            val['mini'] = None
        try:
            maxi = float(val['cmMax'])
            val['maxi'] = maxi
        except:
            maxi = None
            val['maxi'] = None
        cm =  self.vf.colorMaps[val['colormap']]
        self.vf.colorMaps[val['colormap']].configure(mini=mini, maxi=maxi)
 
       # Show the colormapeditor
        if val['editmap']==1:
            self.vf.showCMGUI(cmap=val["colormap"], topCommand=0)
            self.cmg = self.vf.showCMGUI.cmg
            func = CallBackFunction(self.cmGUI_cb,
                                    geomsToColor,
                                    property, 
                                    propertyLevel=self.propertyLevel)
            self.cmg.addCallback(func)

        # Remove the extra key:value 
        del val['cmMax']
        del val['cmMin']
        del val['valMax']
        del val['valMin']
        del val['editmap']
        val['log']=1
        if val.has_key('level'): del val['level']
        val['redraw']=1
        val['propertyLevel'] = self.propertyLevel
        apply(self.doitWrapper, (self.selection, geomsToColor, property), val)


    def cmGUI_cb(self, geomsToColor, property, colormap, propertyLevel=None):
        # 1- Need to log the modification of the colormap
        args = (colormap,)
        kw = {'ramp':colormap.ramp, 'mini':colormap.mini, 'maxi':colormap.maxi}
        lastCmdLog = apply( self.vf.editColorMap.logString, args, kw)
        # This will only add the lastCmdLog to the logFile.
        # This is ok because until the session is closed the changes made
        # to the colormap will last
        self.vf.log(lastCmdLog)
        # 2- Call the colorByProperties
        nodes = self.selection
        self.doitWrapper(nodes, geomsToColor, property, propertyLevel=propertyLevel,
                         colormap=colormap, redraw=1)


    def setupUndoBefore(self, nodes, geomsToColor, property, propertyLevel=None,
                        colormap='RGBARamp', mini=None, maxi=None):
        molecules, atms, nodes = self.getNodes(nodes, returnNodes=True)
        if atms is None:
            self.cleanup()
            return 'ERROR'

        self.undoCmds = ''
        sameColor = 1
        for g in geomsToColor:
            atmsWithGeom = atms.get(lambda x, geom=g: x.colors.has_key(geom))
            if len(atmsWithGeom) > 0:
                    oldColors = []
                    firstCol = atmsWithGeom[0].colors[g]
                    for a in atmsWithGeom:
                        col = a.colors[g]
                        if sameColor:
                            if col[0]!=firstCol[0] or col[1]!=firstCol[1] or \
                               col[2]!=firstCol[2]:
                                sameColor=0
                        oldColors.append( col )
                    if sameColor:
                        oldColors = oldColors[:1]
                    self.addUndoCall( (atmsWithGeom, oldColors, [g]), {'redraw':1},
                                      self.undoCmdsString )


    def doit(self, nodes, geomsToColor, property, propertyLevel=None, colormap=None,
             mini='not passed', maxi='not passed'):

        nodes = nodes.findType(self.vf.selectionLevel)
        molecules, atms, nodes = self.getNodes(nodes, returnNodes=True)
        if nodes is None:
            return 'ERROR'

        if colormap is None:
            colormap = RGBARamp
        elif type(colormap) is types.StringType \
          and self.vf.colorMaps.has_key(colormap):
            colormap = self.vf.colorMaps[colormap]
        if not isinstance(colormap, ColorMap):
            return 'ERROR'

        # Get the list of values corresponding the the chosen property
        # if not already done ?
        if self.getVal == 0:
            self.getPropValues(nodes, property, propertyLevel)
        if self.propValues is None:
            return 'ERROR'
		# build the color ramp.
        selectioncol = colormap.Map(self.propValues, mini=mini, maxi=maxi)
        # Call the colorProp method
        self.colorProp(nodes, geomsToColor, selectioncol, propertyLevel)
        
        insideIntervalnodes = []
        for i in range(len(nodes)):
            if self.propValues[i] >= mini and self.propValues[i] <= maxi:
                insideIntervalnodes.append(nodes[i])
        if nodes[0].__class__.__name__.endswith('Atom'):
            lSet = AtomSet(insideIntervalnodes)
        elif nodes[0].__class__.__name__.endswith('Residue'):
            lSet = ResidueSet(insideIntervalnodes)
        elif nodes[0].__class__.__name__.endswith('Chain'):
            lSet = ChainSet(insideIntervalnodes)
        elif nodes[0].__class__.__name__.endswith('Molecule'):
            lSet = MoleculeSet(insideIntervalnodes)
        elif nodes[0].__class__.__name__.endswith('Protein'):
            lSet = ProteinSet(insideIntervalnodes)

        if 'ColorByProperties' in self.vf.sets.keys():
            self.vf.sets.pop('ColorByProperties')
        self.vf.saveSet(lSet, 'ColorByProperties',
                comments="""Last set created by colorByProperties,
contains only nodes with chosen property between mini and maxi.
This set is ovewritten each time ColorByProperties is called.
"""
               )    

        return lSet

    def colorProp(self, nodes, geomsToColor, selectioncol, propertyLevel=None):
        #
        molecules, atms, nodes = self.getNodes(nodes, returnNodes=True)
        #molecules, atms, nodes = self.getNodes(nodes)
        # molecules, nodeSets = self.vf.getNodesByMolecule(nodes)

        if (propertyLevel is not None) and \
           self.levelOrder[propertyLevel] < self.levelOrder[self.level]:
            #nodes = self.vf.getSelection().findType(self.molDict[propertyLevel])     
            nodes = nodes.findType(self.molDict[propertyLevel])     

        # loop over the node and assign the right color to the atoms.
        deltaOpac = 0.0
        for gName in geomsToColor:
            if nodes[0].__class__ == Atom:
                allAtoms = nodes
                i = 0
                for n in nodes:
                    if n.colors.has_key(gName):
                        n.colors[gName] = tuple(selectioncol[i][:3])
                    if n.opacities.has_key(gName):
                        newOpac = selectioncol[i][3]
                        deltaOpac = deltaOpac + (n.opacities[gName]-newOpac)
                        n.opacities[gName] = newOpac
                    i = i + 1
            else:
                allAtoms = []
                i = 0
                for n in nodes:
                    atms = n.findType(Atom)
                    allAtoms.append(atms)
                    for a in atms:
                        if a.colors.has_key(gName):
                            a.colors[gName] = tuple(selectioncol[i][:3])
                        if a.opacities.has_key(gName):
                            newOpac = selectioncol[i][3]
                            deltaOpac = deltaOpac + (a.opacities[gName]-
                                                     newOpac)
                            a.opacities[gName] = newOpac
                    i = i + 1
        updatedGeomsToColor = []
        for mol in molecules:
            for gName in geomsToColor:
                if not mol.geomContainer.geoms.has_key(gName): continue
                geom = mol.geomContainer.geoms[gName]
                if geom.children != []:
                    # get geom Name:
                    childrenNames = map(lambda x: x.name, geom.children)
                    updatedGeomsToColor = updatedGeomsToColor + childrenNames
                    for childGeom in geom.children:
                        childGeom.Set(inheritMaterial=0, redo=0, tagModified=False)
                else:
                    updatedGeomsToColor.append(gName)
                    geom.Set(inheritMaterial=0, redo=0, tagModified=False)

            updateOpac = (deltaOpac!=0.0)
            mol.geomContainer.updateColors(updatedGeomsToColor,
                                           updateOpacity=updateOpac)
            

    def __call__(self, nodes, geomsToColor, property, propertyLevel=None,
                 colormap='rgb256',mini=None, maxi=None,
                 **kw):
        """None <- colorByProperty(nodes, geomsToColor, property,colormap='rgb256', **kw)
        \nnode --- TreeNodeSet holding the current selection
        \ngeomsToColor --- the list of the name geometries to be colored
        \nproperty ---   property name of type integer or float or property defined by a function returning a list of float or int.
        \ncolormap--- either a string representing a colormap or a DejaVu.ColorMap instance.
        """
        if not kw.has_key('redraw'): kw['redraw'] = 1
        kw['colormap'] = colormap
        kw['mini'] = mini
        kw['maxi'] = maxi
        if type(nodes) is types.StringType:
            self.nodeLogString = "'"+nodes+"'"

        nodes = self.vf.expandNodes(nodes)
        if not nodes:
            return 'ERROR'
        if geomsToColor in ['all', '*'] or 'all' in geomsToColor\
           or '*' in geomsToColor:
            geomsToColor = self.getAvailableGeoms(nodes)
        if not type(geomsToColor) in [types.ListType, types.TupleType]:
            return 'ERROR'
        geomsToColor = filter(lambda x: x not in [' ', ''], geomsToColor)
        if not len(geomsToColor):
            return'ERROR'
        kw['propertyLevel'] = propertyLevel
        status = apply( self.doitWrapper, (nodes, geomsToColor, property), kw)
        return status
    
colorByPropertiesGuiDescr =  {'widgetType':'Menu', 'menuBarName':'menuRoot',
                              'menuButtonName':'Color',
                              'menuEntryLabel':'by Properties'}               
 
ColorByPropertiesGUI = CommandGUI()
ColorByPropertiesGUI.addMenuCommand('menuRoot', 'Color', 'by Properties')



class ColorByExpression(ColorByProperties):
    """The colorByExpression command allows the user to color the given geometries representing the given nodes evaluated by  python function or lambda function.
    \nPackage : Pmv
    \nModule  : colorCommands
    \nClass   : ColorByInstance
    \nCommand : colorByInstance
    \nSynopsis:\n
     None <- colorByExpression(nodes, geomsToColor, function,lambdaFunc, ramp=None, min=None, max=Non)
        \nnodes --- TreeNodeSet holding the current selection
        \ngeomsToColor --- the list of the name geometries to be colored
        \nfunction --- python function or lambda function that will be evaluated with the given nodes
        \nlambdaFunc --- flag specifying if the given function is a lambda function or a regular function
        \ncolormap ---  can either be a string which is the name of a loaded colormap or a DejaVu.colorMap.ColorMap instance.
  """  
    
    # comments for map function definition window
    mapLabel = """Define a function or a lambda function to be applied
on each node of the current selection: """

    # code example for map function definition window
    mapText = '\
#This function returns the value of the attribute _charges["gasteiger"] if\n\
#it exists otherwise returns 0.\n\
#def foo(object):\n\
#\tif hasattr(object, "_charges") and object._charges.has_key("gasteiger"):\n\
#\t\treturn object._charges["gasteiger"]\n\
#\telse:\n\
#\t\treturn 0\n\
#OR\n\
# This lambda function must be applied if at the atom level and gasteiger\n\
# charges computed.\n\
#lambda x: x._charges["gasteiger"]\n'

    # comments for function to operate on selection
    funcLabel = """Define a function to be applied to
the current selection:"""
    
    # code example for function to operate on selection
    funcText ='#def foo(selection):\n#\tvalues = []\n#\t#loop on the current selection\n#\tfor i in xrange(len(selection)):\n#\t\t#build a list of values to color the current selection.\n#\t\tif selection[i].number > 20:\n#\t\t\tvalues.append(selection[i].number*2)\n#\t\telse:\n#\t\t\tvalues.append(selection[i].number)\n#\t# this list of values is then returned.\n#\treturn values\n'

    def __init__(self, func=None):
        ColorCommand.__init__(self, func)
        self.flag = self.flag & 0

    def onAddCmdToViewer(self):
        ColorByProperties.onAddCmdToViewer(self)
        self.evalFlag = 0
        self.propValues=None
        
    def loadCM_cb(self, event=None):
        """ Callback to load a new color map file."""
        filename = self.vf.askFileOpen(types=[('color map files:',
                                               '*_map.py'),
                                              ('all files:', '*')],
                                       title = 'Color Map File:')
        if not filename: return
        cm = self.vf.loadColorMap(filename)
        # then need to update the combobox
        ebn = self.cmdForms['byExpr'].descr.entryByName
        cbb = ebn['colormap']['widget']
        cbb.clear()
        cbb._list.setlist(self.vf.colorMaps.keys())
        cbb.selectitem(cm.name)

    def updateCM(self, event=None):
        ebn = self.cmdForms['byExpr'].descr.entryByName
        mini = ebn['valMin']['widget'].get()
        maxi = ebn['valMax']['widget'].get()
        ebn["cmMin"]['widget'].setentry(mini)
        ebn['cmMax']['widget'].setentry(maxi)

    def updateMiniMaxi(self, cmName, event=None):
        # get the colorMap
        cm = self.vf.colorMaps[cmName]
        mini = cm.mini
        maxi = cm.maxi
        ebn = self.cmdForms['byExpr'].descr.entryByName
        ebn["cmMin"]['widget'].setentry(mini)
        ebn['cmMax']['widget'].setentry(maxi)


    def buildFormDescr(self, formName):
        if formName == 'default':
            idf = ColorCommand.buildFormDescr(self, formName)
            return idf
        elif formName == 'byExpr':
            # Create the form descriptor:
            formTitle = "Color by expression"
            idf = InputFormDescr(title = formTitle)
            #val = self.nameDict[self.vf.ICmdCaller.level.value]
            val = self.level
            listoption = {'Atom':{'bg':'yellow',
                                  'activebackground':'yellow',
                                  'borderwidth':3},
                          'Residue':{'bg':'green',
                                     'activebackground':'green',
                                     'borderwidth':3},
                          'Chain':{'bg':'cyan',
                                   'activebackground':'cyan',
                                   'borderwidth':3},
                          'Molecule':{'bg':'red',
                                      'activebackground':'red',
                                      'borderwidth':3}
                          }
            idf.append({'widgetType':Pmw.RadioSelect,
                        'name':'level',
                        'listtext':['Atom','Residue','Chain','Molecule'],
                        'defaultValue':val,
                        'listoption':self.leveloption,#listoption,
                        'wcfg':{'label_text':'Change the property level:',
                                'labelpos':'nw',
                                'command':self.updateLevel_cb,
                                },
                        'gridcfg':{'sticky':'we','columnspan':2}})
            
            idf.append({'name':'functiontype',
                        'widgetType':Pmw.RadioSelect,
                        'listtext':['lambda function', 'function'],
                        'defaultValue':'lambda function',
                        'wcfg':{'label_text':'Choose Expression type:',
                                'labelpos':'nw','orient':'horizontal',
                                'buttontype':'radiobutton'
                                },
                        'gridcfg':{'sticky': 'w','columnspan':2}})

            self.textContent = self.mapText
            self.textLabel = self.mapLabel
            idf.append({'name':'function',
                        'widgetType':LoadOrSaveText,
                        'defaultValue': self.textContent,
                        'wcfg':{'textwcfg':{'labelpos':'nw',
                                            'label_text': self.textLabel,
                                            'usehullsize':1,
                                            'hull_width':500,
                                            'hull_height':280,
                                            'text_wrap':'none'},
                                },
                        'gridcfg':{'sticky': 'we'}})

            idf.append({'name':'eval',
                        'widgetType':Tkinter.Button,
                        'wcfg':{'text': 'Eval expression',
                                'command':self.eval_cb,
                                },
                        'gridcfg':{'sticky': 'we','row':-1}})
            
            ### COLORMAP
            idf.append({'name':'cmGroup',
                        'widgetType':Pmw.Group,
                        'container':{'cmGroup':"w.interior()"},
                        'wcfg':{'tag_text':"Color Map:"},
                        'gridcfg':{'sticky':'wnse', 'columnspan':2}})

            # Edit map
            idf.append({'name':'editmap',
                        'parent':'cmGroup',
                        'widgetType':Tkinter.Checkbutton,
                        'wcfg':{'text':'Edit',
                                'variable':Tkinter.IntVar()},
                        'gridcfg':{'sticky':'we'}})
            
            cmNames = self.vf.colorMaps.keys()
            if len(cmNames):
                idf.append({'name':'colormap',
                            'parent':'cmGroup',
                            'widgetType':Pmw.ComboBox,
                            'defaultValue':cmNames[0],
                            'required':1,
                            'tooltip':"Choose a colormap",
                            'wcfg':{'scrolledlist_items':cmNames,
                                    'history':0,
                                    'selectioncommand':self.updateMiniMaxi},
                            'gridcfg':{'row':-1,'sticky':'we'}})
            else:
                idf.append({'name':'colormap',
                            'parent':'cmGroup',
                            'widgetType':Pmw.ComboBox,
                            'required':1,
                            'tooltip':"Choose a colormap",
                            'wcfg':{'scrolledlist_items':cmNames,
                                    'history':0,
                                    'selectioncommand':self.updateMiniMaxi},
                            'gridcfg':{'row':-1,'sticky':'we'}})
                
            idf.append({'name':'loadCM',
                        'parent':'cmGroup',
                        'widgetType':Tkinter.Button,
                        'wcfg':{'text':'Load',
                                'command':self.loadCM_cb,
                                },
                        'gridcfg':{'row':-1}})

            idf.append({'name':'minMax',
                        'widgetType':Pmw.Group,
                        'parent':'cmdGroup',
                        'container':{"minMax":"w.interior()"},
                        'gridcfg':{'sticky':'wnse','columnspan':2}})

            idf.append({'name':'valueMiniMaxi',
                        'widgetType':Pmw.Group,
                        'parent':'minMax',
                        'container':{"valminimaxi":'w.interior()'},
                        'wcfg':{'tag_text':"Property Values:"},
                        'gridcfg':{'sticky':'wnse'}})

            
            idf.append({'name':'updateCM',
                        'parent':'minMax',
                        'widgetType':Tkinter.Button,
                        'tooltip':"Update the ColorMap mini and maxi values \n with the property values mini\
and maxi",
                        'wcfg':{'text':">>", 'command':self.updateCM},
                        'gridcfg':{'row':-1}
                        })


            idf.append({'name':'cmninmaxi',
                        'widgetType':Pmw.Group,
                        'parent':'minMax',
                        'container':{"cmminimaxi":'w.interior()'},
                        'wcfg':{'tag_text':"ColorMap:"},
                        'gridcfg':{'sticky':'wnse', 'row':-1}})
            
            idf.append({'name':"valMin",
                        'widgetType':Pmw.EntryField,
                        'parent':'valminimaxi',
                        'wcfg':{'label_text':'Minimum',
                                'labelpos':'w'},
                        })
            idf.append({'name':"valMax",
                        'widgetType':Pmw.EntryField,
                        'parent':'valminimaxi',
                        'wcfg':{'label_text':'Maximum',
                                'labelpos':'w'},
                        })
            
            if len(cmNames):
                cmMin = self.vf.colorMaps[cmNames[0]].mini
                cmMax = self.vf.colorMaps[cmNames[0]].maxi
                idf.append({'name':"cmMin",
                            'widgetType':Pmw.EntryField,
                            'parent':'cmminimaxi',
                            'wcfg':{'label_text':'Minimum',
                                    'labelpos':'w',
                                    'value':cmMin},
                            'gridcfg':{}
                            })

                idf.append({'name':"cmMax",
                            'widgetType':Pmw.EntryField,
                            'parent':'cmminimaxi',
                            'wcfg':{'label_text':'Maximum',
                                    'labelpos':'w',
                                    'value':cmMax},
                            })
            else:
                idf.append({'name':"cmMin",
                            'widgetType':Pmw.EntryField,
                            'parent':'cmminimaxi',
                            'wcfg':{'label_text':'Minimum',
                                    'labelpos':'w'},
                            'gridcfg':{}
                            })

                idf.append({'name':"cmMax",
                            'widgetType':Pmw.EntryField,
                            'parent':'cmminimaxi',
                            'wcfg':{'label_text':'Maximum',
                                    'labelpos':'w'},
                            })

            return idf


    def eval_cb(self):
        ebn = self.cmdForms['byExpr'].descr.entryByName
        lambdaFunc = ebn['functiontype']['widget'].getcurselection()
        function = ebn['function']['widget'].get()
        self.getPropValues(self.selection, function, lambdaFunc)
        self.evalFlag = 1
        minEntry = ebn['valMin']['widget']
        maxEntry = ebn['valMax']['widget']
        self.getVal = 1
        if self.propValues is None :
            mini = 0
            maxi = 0
        else:
            mini = min(self.propValues)
            maxi = max(self.propValues)
        minEntry.setentry(mini)
        maxEntry.setentry(maxi)
        
    def setupUndoBefore(self, nodes, geomsToColor,
                        function='lambda x: x._uniqIndex',
                        lambdaFunc = 1, colormap='RGBARamp'):
        if not nodes: return
        molecules, atms, nodes = self.getNodes(nodes, returnNodes=True)
        if atms is None:
            return

        self.undoCmds = ''
        sameColor = 1

        for g in geomsToColor:
            atmsWithGeom = atms.get(lambda x, geom=g: x.colors.has_key(geom))
            oldColors = []
            firstCol = atmsWithGeom[0].colors[g]
            
            for a in atmsWithGeom:
                col = a.colors[g]
                if sameColor:
                    if col[0]!=firstCol[0] or col[1]!=firstCol[1] or \
                       col[2]!=firstCol[2]:
                        sameColor=0
                oldColors.append( col )

            if sameColor:
                oldColors = oldColors[:1]

            self.addUndoCall( (atmsWithGeom, oldColors, [g]), {'redraw':1},
                              self.undoCmdsString )

    def cmGUI_cb(self, geomsToColor, function, lambdaFunc, colormap):
        # 1- Need to log the modification of the colormap
        args = (colormap,)
        kw = {'ramp':colormap.ramp, 'mini':colormap.mini, 'maxi':colormap.maxi}
        lastCmdLog = apply( self.vf.editColorMap.logString, args, kw)
        # This will only add the lastCmdLog to the logFile.
        # This is ok because until the session is closed the changes made
        # to the colormap will last
        self.vf.log(lastCmdLog)

        # 2- Call the colorByExpression
        self.doitWrapper(self.selection, geomsToColor, function, lambdaFunc,
                         colormap=colormap, redraw=1)



    def guiCallback(self):
        # return is no molecule loaded:
        self.evalFlag = 0
        self.propValues = None

        self.selection = self.vf.getSelection()
        #self.selection.sort()
        if len(self.selection)==0:
            return 'ERROR' # to prevent logging
        self.level = self.nameDict[self.vf.selectionLevel]
        # Get the geometry to color
        val = self.showForm('default', scrolledFrame = 1,
                            width= 500, height = 200, force=1)
        if val:
            geomsToColor = val['geomsToColor']
        else:
            geomsToColor = None
##             self.warningMsg("ERROR: No geometry to color")
            return 'ERROR'

        # Update the level if the form exists already.
        if self.cmdForms.has_key('byExpr'):
            ebn = self.cmdForms['byExpr'].descr.entryByName
            levelwid = ebn['level']['widget']
            oldlevel = levelwid.getcurselection()
            #if oldlevel != self.nameDict[self.vf.ICmdCaller.level.value]:
            #    levelwid.invoke(self.nameDict[self.vf.ICmdCaller.level.value])
            if oldlevel != self.level:
                levelwid.invoke(self.level)
            # Update the colormaps combobox
            cbb = ebn['colormap']['widget']
            cbb.clear()
            cms = self.vf.colorMaps.keys()
            cbb._list.setlist(cms)
            cbb.selectitem(cms[0])
            

        val = self.showForm('byExpr')
        if not val: return
        if val['functiontype'] == 'lambda function':
            val['lambdaFunc'] = 1
            del val['functiontype']

        elif val['functiontype'] == 'function':
            val['lambdaFunc'] = 0
            del val['functiontype']
        val['colormap']=val['colormap'][0]

        mini = float(val['cmMin'])
        maxi= float(val['cmMax'])
        cm =  self.vf.colorMaps[val['colormap']]
        self.vf.colorMaps[val['colormap']].configure(mini=mini,
                                                     maxi=maxi)

        # Show the colormapeditor
        if val['editmap']==1:
            function = val['function']
            lambdaFunc = val['lambdaFunc']
            if self.getVal == 0:
                self.getPropValues(self.selection, function,
                                   lambdaFunc)
            self.vf.showCMGUI(cmap=val["colormap"], topCommand=0)
            self.cmg = self.vf.showCMGUI.cmg
            func = CallBackFunction(self.cmGUI_cb, geomsToColor, function,
                                    lambdaFunc)
            self.cmg.addCallback(func)
        del val['cmMax']
        del val['cmMin']
        del val['valMax']
        del val['valMin']
           
        del val['editmap']

        val['redraw'] = 1
        if val.has_key('level'): del val['level']
        apply(self.doitWrapper, (self.selection,geomsToColor), val)


    def __call__(self, nodes,  geomsToColor='all',
                 function='lambda x: x._uniqIndex',
                 lambdaFunc = 1, colormap='RGBARamp', **kw):
        """None <- colorByExpression(nodes, geomsToColor, function,lambdaFunc, ramp=None,min=None, max=None, **kw)
        \nnodes --- TreeNodeSet holding the current selection
        \ngeomsToColor --- the list of the name geometries to be colored
        \nfunction --- python function or lambda function that will be evaluated with the given nodes
        \nlambdaFunc --- flag specifying if the given function is a lambda function or a regular function
        \ncolormap ---  can either be a string which is the name of a loaded colormap or a DejaVu.colorMap.ColorMap instance.
        """

        kw['function'] = function
        kw['lambdaFunc'] = lambdaFunc
        kw['colormap'] = colormap
        kw['redraw'] = 1
        if type(nodes) is types.StringType:
            self.nodeLogString = nodes
        nodes = self.vf.expandNodes(nodes)
        if not nodes:
            return "ERROR"
        kw['redraw'] = 1
        if geomsToColor in ['all', '*'] or 'all' in geomsToColor\
           or '*' in geomsToColor:
            geomsToColor = self.getAvailableGeoms(nodes)
        if not type(geomsToColor) in [types.ListType, types.TupleType]:
            return "ERROR"
        geomsToColor = filter(lambda x: x not in [' ', ''], geomsToColor)
        if not len(geomsToColor): return "ERROR"
        status = apply(self.doitWrapper, (nodes, geomsToColor), kw)
        return status
    
    def getPropValues(self, nodes, function, lambdaFunc):
        try:
            func = evalString(function)
        except:
            self.warningMsg("Error occured while evaluating the expression")
            traceback.print_exc()
            return

        if lambdaFunc == 1:
            try:
                self.propValues = map(func, nodes)
            except KeyError:
                msg= "Some nodes do not have this property, therefore the current selection cannot be colored using this function."
                self.warningMsg(msg)
                self.propValues = None
        else:
            try:
                self.propValues = func(nodes)
            except:
                msg= "Some nodes do not have this property, therefore the current selection cannot be colored using this function."
                self.warningMsg(msg)
                self.propValues = None

        
    def doit(self, nodes,  geomsToColor,
             function='lambda x: x._uniqIndex',
             lambdaFunc=1, colormap='RGBARamp'):

        molecules, atms, nodes = self.getNodes(nodes, returnNodes=True)
        if atms is None:
            return "ERROR"
        # Get the colormap
        if type(colormap) is types.StringType and \
           self.vf.colorMaps.has_key(colormap):
            colormap = self.vf.colorMaps[colormap]
        elif not isinstance(colormap, ColorMap):
            return "ERROR"
        # get the values
        if self.evalFlag==0:
            self.getPropValues(nodes, function, lambdaFunc)
            if self.propValues is None:
                return "ERROR"


        # Get the color corresponding the values
        selectioncol = colormap.Map(self.propValues, colormap.mini,
                                    colormap.maxi)
        
        self.colorProp(nodes, geomsToColor, selectioncol)


colorByExpressionGuiDescr =  {'widgetType':'Menu', 'menuBarName':'menuRoot',
                              'menuButtonName':'Color',
                              'menuEntryLabel':'by Expression'}               

ColorByExpressionGUI = CommandGUI()
ColorByExpressionGUI.addMenuCommand('menuRoot', 'Color', 'by Expression')


commandList = [
    {'name':'color','cmd':ColorCommand(), 'gui': ColorGUI},
    {'name':'colorByAtomType', 'cmd':ColorByAtomType(),
     'gui':ColorByAtomTypeGUI},
    {'name':'colorByResidueType', 'cmd':ColorByResidueType(),
     'gui':ColorByResidueTypeGUI},
    {'name':'colorAtomsUsingDG', 'cmd':ColorByDG(), 'gui':ColorByDGGUI},
    {'name':'colorResiduesUsingShapely', 'cmd':ColorShapely(),
     'gui':ColorShapelyGUI},
    {'name':'colorByChains', 'cmd':ColorByChain(), 'gui':ColorByChainGUI},
    {'name':'colorByMolecules', 'cmd':ColorByMolecule(),
     'gui':ColorByMoleculeGUI},
    {'name':'colorByInstance', 'cmd':ColorByInstance(),
     'gui':ColorByInstanceGUI},
    {'name':'colorByProperty', 'cmd':ColorByProperties(),
     'gui':ColorByPropertiesGUI},
    {'name':'colorByExpression', 'cmd':ColorByExpression(),
     'gui':ColorByExpressionGUI},
    ]


def initModule(viewer):
    for dict in commandList:
        viewer.addCommand(dict['cmd'], dict['name'], dict['gui'])
