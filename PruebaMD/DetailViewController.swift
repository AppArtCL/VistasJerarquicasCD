//
//  DetailViewController.swift
//  PruebaMD
//
//  Created by Cristian Diaz on 30-11-15.
//  Copyright © 2015 AppArt. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {

    // MARK: - Conexiones

    @IBOutlet weak var codigoISBN: UITextField!
    @IBOutlet weak var indicadorActividad: UIActivityIndicatorView!
    @IBOutlet weak var etiquetaNombreLibro: UILabel!
    @IBOutlet weak var etiquetaAutores: UILabel!
    @IBOutlet weak var imagenPortada: UIImageView!

    @IBAction func codigoISBN(sender: AnyObject) {
        buscaCodigo(self.codigoISBN.text!)
    }
    
    
    // MARK: - Variables

    var opcion = 0
    var libroBuscado = ""
    
    var codigoError = 0
    var texto = ""
    var tituloLibro = ""
    var autores = ""
    var urlPortada = ""
    
    var detailItem: AnyObject? {
        didSet {
            // Update the view.
            self.configureView()
        }
    }
    
    // MARK: - Funciones
    
    func borraTodo(){
        self.etiquetaAutores.text = ""
        self.etiquetaNombreLibro.text = ""
        self.imagenPortada.image = nil
    }
    
    func buscaCodigo(codigoBuscado: String){
        self.codigoError = 0
        self.tituloLibro = ""
        self.autores = ""
        self.urlPortada = ""
        borraTodo()
        if codigoBuscado == "" {
            let alerta = UIAlertController(title: "Error en la búsqueda", message: "El código no puede ser vacío.", preferredStyle: UIAlertControllerStyle.Alert)
            alerta.addAction(UIAlertAction(title: "OK", style: .Default, handler: {(alertAction) -> Void in
                //self.codigoISBN.text = ""
                //self.detalleCodigoISBN.text = ""
            }))
            self.presentViewController(alerta, animated: true, completion: nil)
        } else {
            self.indicadorActividad.startAnimating()
            obtenerTextoISBN2(codigoBuscado)
        }
    }
    
    func obtenerTextoISBN2(codigo:String) {
        let consulta = NSMutableURLRequest(URL: NSURL(string: "https://openlibrary.org/api/books?jscmd=data&format=json&bibkeys=ISBN:" + codigo)!)
        let sesion = NSURLSession.sharedSession()
        consulta.HTTPMethod = "GET"
        let task = sesion.dataTaskWithRequest(consulta, completionHandler: {data, respuesta, error -> Void in
            if let datosRespuesta = respuesta as? NSHTTPURLResponse {
                if datosRespuesta.statusCode == 200 {
                    if data != nil {
                        self.texto = String(data: data!, encoding: NSUTF8StringEncoding)!
                        if self.texto == "{}" {
                            self.texto = ""
                            self.codigoError = 2
                        } else {
                            
                            do {
                                let jsonCompleto = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.MutableLeaves)
                                let json = jsonCompleto as! NSDictionary
                                //***let nombreJSON = "ISBN:" + self.codigoISBN.text!
                                let nombreJSON = "ISBN:" + codigo
                                
                                // Conseguir nombre del texto
                                if let nombreTemp = json[nombreJSON]!["title"] as? String {
                                    self.tituloLibro = nombreTemp
                                } else {
                                    self.tituloLibro = "Texto sin nombre"
                                }
                                
                                // Conseguir autores del texto
                                if let listaAutores = json[nombreJSON]!["authors"] as? NSArray {
                                    let autorDeLista = listaAutores[0] as! NSDictionary
                                    self.autores = autorDeLista["name"]! as! String
                                    if listaAutores.count > 1 {
                                        for var i = 1; i < listaAutores.count; i++ {
                                            self.autores = self.autores + "; " + (listaAutores[i]["name"]! as! String)
                                        }
                                    }
                                    self.autores = self.autores + "."
                                } else {
                                    self.autores = "Texto sin autor"
                                }
                                
                                // Conseguir imagen de portada si la hay
                                if let portadasLibro = json[nombreJSON]!["cover"] as? NSDictionary {
                                    self.urlPortada = portadasLibro["medium"]! as! String
                                }
                            }
                            catch _ {
                                
                            }
                        }
                    } else {
                        print(error?.localizedDescription)
                        self.codigoError = 2
                    }
                } else {
                    //self.codigoError = Int(datosRespuesta.statusCode)
                    self.codigoError = 1
                }
            } else {
                self.codigoError = 1
            }
            self.refrescaPantalla()
        })
        task.resume()
    }
    
    // Espera al termino de la cola y ejecuta los siguientes
    func refrescaPantalla() {
        dispatch_async(dispatch_get_main_queue(), {
            self.etiquetaNombreLibro.text = self.tituloLibro
            self.etiquetaAutores.text = self.autores
            self.indicadorActividad.stopAnimating()
            
            let urlImagen = NSURL(string: self.urlPortada)
            let datosImagen = NSData(contentsOfURL: urlImagen!)
            if datosImagen != nil {
                self.imagenPortada.image = UIImage(data: datosImagen!)
            } else {
                self.imagenPortada.image = UIImage(named: "NoExiste.png")
            }
            
            if self.codigoError == 1 {
                let alerta = UIAlertController(title: "Error en la búsqueda", message: "Existe problema con la conexión a Internet.", preferredStyle: UIAlertControllerStyle.Alert)
                alerta.addAction(UIAlertAction(title: "OK", style: .Default, handler: {(alertAction) -> Void in
                    self.codigoISBN.text = ""
                }))
                self.presentViewController(alerta, animated: true, completion: nil)
            } else if self.codigoError == 2 {
                let alerta = UIAlertController(title: "Error en la búsqueda", message:
                    "No existe libro con codigo \(self.codigoISBN.text!)", preferredStyle: .Alert)
                //alerta.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
                alerta.addAction(UIAlertAction(title: "OK", style: .Default, handler: {(alertAction) -> Void in
                    self.codigoISBN.text = ""
                }))
                self.presentViewController(alerta, animated: true, completion: nil)
            } else if self.codigoError == 0 {
                // Agregar el item en listadoLibros
                if self.opcion == 1 {
                  listadoLibros.append(self.codigoISBN.text!)
                }
            }
            return
        })
    }
    
    
    func configureView() {
        // Update the user interface for the detail item.
//****        if let detail = self.detailItem {
//****            if let label = self.detailDescriptionLabel {
//****                label.text = detail.valueForKey("timeStamp")!.description
//****            }
//****        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.indicadorActividad.stopAnimating()

        if opcion == 0 {
            self.configureView()
            codigoISBN.hidden = true
            buscaCodigo(libroBuscado)
            
            
        } else if opcion == 1 {
            codigoISBN.hidden = false
            borraTodo()
            codigoISBN.becomeFirstResponder()
            
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}