//
//  Controller.swift
//  Azul
//
//  Copyright © 2016 Ken Arroyo Ohori. All rights reserved.
//

import Cocoa
import OpenGL.GL3
import GLKit

@NSApplicationMain
class Controller: NSObject, NSApplicationDelegate {

  @IBOutlet weak var window: NSWindow!
  @IBOutlet weak var openGLView: OpenGLView!
  @IBOutlet weak var progressIndicator: NSProgressIndicator!
  
  let cityGMLParser = CityGMLParserWrapperWrapper()
  
  var openFiles = Set<URL>()
  var loadingData: Bool = false

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    Swift.print("Controller.applicationDidFinishLaunching()")
    openGLView.controller = self
  }

  func applicationWillTerminate(_ aNotification: Notification) {
    // Insert code here to tear down your application
  }
  
  func application(_ sender: NSApplication, openFile filename: String) -> Bool {
    Swift.print("Controller.application(NSApplication, openFile: String)")
    Swift.print("Open \(filename)")
    let url = URL(fileURLWithPath: filename)
    self.loadData(from: [url])
    return true
  }
  
  func application(_ sender: NSApplication, openFiles filenames: [String]) {
    Swift.print("Controller.application(NSApplication, openFiles: String)")
    Swift.print("Open \(filenames)")
    var urls = [URL]()
    for filename in filenames {
      urls.append(URL(fileURLWithPath: filename))
      
    }
    self.loadData(from: urls)
  }
  
  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }
  
  func updateProgressIndicator() {
//    Swift.print("Controller.updateProgressIndicatorUntilDone")
    
  }
  
  @IBAction func new(_ sender: NSMenuItem) {
    Swift.print("Controller.new(NSMenuItem)")
    
    openFiles = Set<URL>()
    self.window.representedURL = nil
    self.window.title = "Azul"
    
    cityGMLParser!.clear()
    
    openGLView.buildingsTriangles.removeAll()
    openGLView.buildingRoofsTriangles.removeAll()
    openGLView.roadsTriangles.removeAll()
    openGLView.waterTriangles.removeAll()
    openGLView.plantCoverTriangles.removeAll()
    openGLView.terrainTriangles.removeAll()
    openGLView.edges.removeAll()
    
    regenerateOpenGLRepresentation()
  }

  @IBAction func openFile(_ sender: NSMenuItem) {
    Swift.print("Controller.openFile(NSMenuItem)")
    
    let openPanel = NSOpenPanel()
    openPanel.allowsMultipleSelection = true
    openPanel.canChooseDirectories = false
    openPanel.canChooseFiles = true
    openPanel.allowedFileTypes = ["gml", "xml"]
    openPanel.begin(completionHandler:{(result: Int) in
      if result == NSFileHandlingPanelOKButton {
        self.loadData(from: openPanel.urls)
      }
    })
  }
  
  func loadData(from urls: [URL]) {
    Swift.print("Controller.loadData(URL)")
    Swift.print("Opening \(urls)")
    
    self.loadingData = true
    let updateProgressTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.updateProgressIndicator), userInfo: nil, repeats: true)
    
    DispatchQueue.global().async(qos: .userInitiated) {
      for url in urls {
    
        if self.openFiles.contains(url) {
          Swift.print("\(url) already open")
          continue
        }
        
//        Swift.print("Loading \(url)")
        url.path.utf8CString.withUnsafeBufferPointer { pointer in
          self.cityGMLParser!.parse(pointer.baseAddress)
        }
  
        self.openFiles.insert(url)
        switch self.openFiles.count {
        case 0:
          self.window.representedURL = nil
          self.window.title = "Azul"
        case 1:
          self.window.representedURL = url
          self.window.title = url.lastPathComponent
        default:
          self.window.representedURL = nil
          self.window.title = "Azul (\(self.openFiles.count) open files)"
        }
        
      }
      
      self.regenerateOpenGLRepresentation()
      updateProgressTimer.invalidate()
      self.loadingData = false
      
      DispatchQueue.main.async {
        self.openGLView.renderFrame()
      }
    }
  }
  
  func regenerateOpenGLRepresentation() {
    openGLView.buildingsTriangles.removeAll()
    openGLView.buildingRoofsTriangles.removeAll()
    openGLView.roadsTriangles.removeAll()
    openGLView.waterTriangles.removeAll()
    openGLView.plantCoverTriangles.removeAll()
    openGLView.terrainTriangles.removeAll()
    openGLView.edges.removeAll()
    
    cityGMLParser!.initialiseIterator()
    while !cityGMLParser!.hasIteratorEnded() {
//      Swift.print("Iterating...")
      
      var numberOfEdgeVertices: UInt = 0
      let firstElementOfEdgesBuffer = cityGMLParser!.getEdgesBuffer(&numberOfEdgeVertices)
      let edgesBuffer = UnsafeBufferPointer(start: firstElementOfEdgesBuffer, count: Int(numberOfEdgeVertices))
      let edges = ContiguousArray(edgesBuffer)
      var numberOfTriangleVertices: UInt = 0
      let firstElementOfTrianglesBuffer = cityGMLParser!.getTrianglesBuffer(&numberOfTriangleVertices)
      let trianglesBuffer = UnsafeBufferPointer(start: firstElementOfTrianglesBuffer, count: Int(numberOfTriangleVertices))
      let triangles = ContiguousArray(trianglesBuffer)
      var numberOfTriangleVertices2: UInt = 0
      let firstElementOfTrianglesBuffer2 = cityGMLParser!.getTriangles2Buffer(&numberOfTriangleVertices2)
      let trianglesBuffer2 = UnsafeBufferPointer(start: firstElementOfTrianglesBuffer2, count: Int(numberOfTriangleVertices2))
      let triangles2 = ContiguousArray(trianglesBuffer2)
      
      openGLView.edges.append(contentsOf: edges)
      
      switch cityGMLParser!.getType() {
      case 1:
        openGLView.buildingsTriangles.append(contentsOf: triangles)
        openGLView.buildingRoofsTriangles.append(contentsOf: triangles2)
      case 2:
        openGLView.roadsTriangles.append(contentsOf: triangles)
      case 3:
        openGLView.waterTriangles.append(contentsOf: triangles)
      case 4:
        openGLView.plantCoverTriangles.append(contentsOf: triangles)
      case 5:
        openGLView.terrainTriangles.append(contentsOf: triangles)
      case 6:
        openGLView.genericTriangles.append(contentsOf: triangles)
      default:
        break
      }
      
      cityGMLParser!.advanceIterator()
    }
    
    openGLView.openGLContext!.makeCurrentContext()
    if glGetError() != GLenum(GL_NO_ERROR) {
      Swift.print("There's a previous OpenGL error")
    }
    
    glBindBuffer(GLenum(GL_ARRAY_BUFFER), openGLView.vboBuildings)
    openGLView.buildingsTriangles.withUnsafeBufferPointer { pointer in
      glBufferData(GLenum(GL_ARRAY_BUFFER), openGLView.buildingsTriangles.count*MemoryLayout<GLfloat>.size, pointer.baseAddress, GLenum(GL_STATIC_DRAW))
    }
    if glGetError() != GLenum(GL_NO_ERROR) {
      Swift.print("Loading building triangles into memory: some error occurred!")
    }
    glBindBuffer(GLenum(GL_ARRAY_BUFFER), openGLView.vboBuildingRoofs)
    openGLView.buildingRoofsTriangles.withUnsafeBufferPointer { pointer in
      glBufferData(GLenum(GL_ARRAY_BUFFER), openGLView.buildingRoofsTriangles.count*MemoryLayout<GLfloat>.size, pointer.baseAddress, GLenum(GL_STATIC_DRAW))
    }
    if glGetError() != GLenum(GL_NO_ERROR) {
      Swift.print("Loading building roof triangles into memory: some error occurred!")
    }
    glBindBuffer(GLenum(GL_ARRAY_BUFFER), openGLView.vboRoads)
    openGLView.roadsTriangles.withUnsafeBufferPointer { pointer in
      glBufferData(GLenum(GL_ARRAY_BUFFER), openGLView.roadsTriangles.count*MemoryLayout<GLfloat>.size, pointer.baseAddress, GLenum(GL_STATIC_DRAW))
    }
    if glGetError() != GLenum(GL_NO_ERROR) {
      Swift.print("Loading road triangles into memory: some error occurred!")
    }
    glBindBuffer(GLenum(GL_ARRAY_BUFFER), openGLView.vboWater)
    openGLView.waterTriangles.withUnsafeBufferPointer { pointer in
      glBufferData(GLenum(GL_ARRAY_BUFFER), openGLView.waterTriangles.count*MemoryLayout<GLfloat>.size, pointer.baseAddress, GLenum(GL_STATIC_DRAW))
    }
    if glGetError() != GLenum(GL_NO_ERROR) {
      Swift.print("Loading water body triangles into memory: some error occurred!")
    }
    glBindBuffer(GLenum(GL_ARRAY_BUFFER), openGLView.vboPlantCover)
    openGLView.plantCoverTriangles.withUnsafeBufferPointer { pointer in
      glBufferData(GLenum(GL_ARRAY_BUFFER), openGLView.plantCoverTriangles.count*MemoryLayout<GLfloat>.size, pointer.baseAddress, GLenum(GL_STATIC_DRAW))
    }
    if glGetError() != GLenum(GL_NO_ERROR) {
      Swift.print("Loading plant cover triangles into memory: some error occurred!")
    }
    glBindBuffer(GLenum(GL_ARRAY_BUFFER), openGLView.vboTerrain)
    openGLView.terrainTriangles.withUnsafeBufferPointer { pointer in
      glBufferData(GLenum(GL_ARRAY_BUFFER), openGLView.terrainTriangles.count*MemoryLayout<GLfloat>.size, pointer.baseAddress, GLenum(GL_STATIC_DRAW))
    }
    if glGetError() != GLenum(GL_NO_ERROR) {
      Swift.print("Loading terrain triangles into memory: some error occurred!")
    }
    glBindBuffer(GLenum(GL_ARRAY_BUFFER), openGLView.vboGeneric)
    openGLView.genericTriangles.withUnsafeBufferPointer { pointer in
      glBufferData(GLenum(GL_ARRAY_BUFFER), openGLView.genericTriangles.count*MemoryLayout<GLfloat>.size, pointer.baseAddress, GLenum(GL_STATIC_DRAW))
    }
    if glGetError() != GLenum(GL_NO_ERROR) {
      Swift.print("Loading generic triangles into memory: some error occurred!")
    }
    glBindBuffer(GLenum(GL_ARRAY_BUFFER), openGLView.vboEdges)
    openGLView.edges.withUnsafeBufferPointer { pointer in
      glBufferData(GLenum(GL_ARRAY_BUFFER), openGLView.edges.count*MemoryLayout<GLfloat>.size, pointer.baseAddress, GLenum(GL_STATIC_DRAW))
    }
    if glGetError() != GLenum(GL_NO_ERROR) {
      Swift.print("Loading edges into memory: some error occurred!")
    }
    
    Swift.print("Loaded triangles: \(openGLView.buildingsTriangles.count) from buildings, \(openGLView.buildingRoofsTriangles.count) from building roofs, \(openGLView.roadsTriangles.count) from roads, \(openGLView.waterTriangles.count) from water bodies, \(openGLView.plantCoverTriangles.count) from plant cover, \(openGLView.genericTriangles.count) from generic objects.")
    Swift.print("Loaded \(openGLView.edges.count) edges.")
  }
}

