import { useState } from 'react';
export default function DessertCart() {
  const [cart, setCart] = useState([]);

  const products = [
    { id: 1, name: 'Waffle with Berries', category: 'Waffle', price: 6.50 },
    { id: 2, name: 'Vanilla Bean Crème Brûlée', category: 'Crème Brûlée', price: 7.00 },
    { id: 3, name: 'Macaron Mix of Five', category: 'Macaron', price: 8.00 },
    { id: 4, name: 'Classic Tiramisu', category: 'Tiramisu', price: 5.50 },
    { id: 5, name: 'Pistachio Baklava', category: 'Baklava', price: 4.00 },
    { id: 6, name: 'Lemon Meringue Pie', category: 'Pie', price: 5.00 },
    { id: 7, name: 'Red Velvet Cake', category: 'Cake', price: 4.50 },
    { id: 8, name: 'Salted Caramel Brownie', category: 'Brownie', price: 4.50 },
    { id: 9, name: 'Vanilla Panna Cotta', category: 'Panna Cotta', price: 6.50 }
  ];

  const addToCart = (product) => {
    setCart(prevCart => {
      const existingItem = prevCart.find(item => item.id === product.id);
      if (existingItem) {
        return prevCart.map(item =>
          item.id === product.id
            ? { ...item, quantity: item.quantity + 1 }
            : item
        );
      }
      return [...prevCart, { ...product, quantity: 1 }];
    });
  };

  const removeFromCart = (productId) => {
    setCart(prevCart => {
      return prevCart.reduce((acc, item) => {
        if (item.id === productId) {
          if (item.quantity > 1) {
            acc.push({ ...item, quantity: item.quantity - 1 });
          }
        } else {
          acc.push(item);
        }
        return acc;
      }, []);
    });
  };

  const getTotalQuantity = () => {
    return cart.reduce((total, item) => total + item.quantity, 0);
  };

  const getTotalPrice = () => {
    return cart.reduce((total, item) => total + (item.price * item.quantity), 0);
  };

  const getItemQuantity = (productId) => {
    const item = cart.find(item => item.id === productId);
    return item ? item.quantity : 0;
  };

  return (
    <div className="min-h-screen bg-rose-50 p-4">
      <div className="max-w-6xl mx-auto">
        <div className="grid lg:grid-cols-4 gap-8">
          {/* Products Section */}
          <div className="lg:col-span-3">
            <h1 className="text-4xl font-bold text-rose-900 mb-8">Desserts</h1>
            
            <div className="grid md:grid-cols-2 xl:grid-cols-3 gap-6">
              {products.map(product => {
                const quantity = getItemQuantity(product.id);
                return (
                  <div key={product.id} className="bg-white rounded-xl p-4 shadow-sm hover:shadow-md transition-shadow">
                    <div className="aspect-square bg-gradient-to-br from-rose-100 to-orange-100 rounded-lg mb-4 flex items-center justify-center">
                      <div className="text-center text-rose-400">
                        <div className="text-2xl mb-2">🍰</div>
                        <div className="text-xs">{product.category}</div>
                      </div>
                    </div>
                    
                    <div className="space-y-2">
                      <p className="text-sm text-rose-400 font-medium">{product.category}</p>
                      <h3 className="font-semibold text-rose-900">{product.name}</h3>
                      <p className="text-red-500 font-bold">${product.price.toFixed(2)}</p>
                    </div>

                    {quantity === 0 ? (
                      <button
                        onClick={() => addToCart(product)}
                        className="w-full mt-4 bg-white border-2 border-red-500 text-red-500 py-2 px-4 rounded-full font-semibold hover:bg-red-500 hover:text-white transition-all duration-200 flex items-center justify-center gap-2"
                      >
                        <span className="text-lg">🛒</span>
                        Add to Cart
                      </button>
                    ) : (
                      <div className="w-full mt-4 bg-red-500 text-white py-2 px-4 rounded-full font-semibold flex items-center justify-between">
                        <button
                          onClick={() => removeFromCart(product.id)}
                          className="w-6 h-6 rounded-full border border-white flex items-center justify-center hover:bg-white hover:text-red-500 transition-colors"
                        >
                          −
                        </button>
                        <span>{quantity}</span>
                        <button
                          onClick={() => addToCart(product)}
                          className="w-6 h-6 rounded-full border border-white flex items-center justify-center hover:bg-white hover:text-red-500 transition-colors"
                        >
                          +
                        </button>
                      </div>
                    )}
                  </div>
                );
              })}
            </div>
          </div>

          {/* Cart Section */}
          <div className="lg:col-span-1">
            <div className="bg-white rounded-xl p-6 shadow-sm sticky top-4">
              <h2 className="text-2xl font-bold text-red-500 mb-6">
                Your Cart ({getTotalQuantity()})
              </h2>

              {cart.length === 0 ? (
                <div className="text-center py-8">
                  <div className="text-4xl mb-4">🍰</div>
                  <p className="text-rose-400">Your added items will appear here</p>
                </div>
              ) : (
                <div className="space-y-4">
                  {cart.map(item => (
                    <div key={item.id} className="flex justify-between items-center py-2 border-b border-rose-100">
                      <div className="flex-1">
                        <h4 className="font-medium text-rose-900 text-sm">{item.name}</h4>
                        <div className="flex items-center gap-3 mt-1">
                          <span className="text-red-500 font-semibold">{item.quantity}x</span>
                          <span className="text-rose-400">@ ${item.price.toFixed(2)}</span>
                          <span className="text-rose-600 font-semibold">${(item.price * item.quantity).toFixed(2)}</span>
                        </div>
                      </div>
                      <button
                        onClick={() => removeFromCart(item.id)}
                        className="ml-4 w-5 h-5 rounded-full border border-rose-300 flex items-center justify-center text-rose-400 hover:border-rose-500 hover:text-rose-600 transition-colors"
                      >
                        ×
                      </button>
                    </div>
                  ))}
                  
                  <div className="pt-4 border-t border-rose-200">
                    <div className="flex justify-between items-center">
                      <span className="text-rose-900 font-medium">Order Total</span>
                      <span className="text-2xl font-bold text-rose-900">${getTotalPrice().toFixed(2)}</span>
                    </div>
                    
                    <button className="w-full mt-6 bg-red-500 text-white py-3 px-6 rounded-full font-semibold hover:bg-red-600 transition-colors">
                      Confirm Order
                    </button>
                  </div>
                </div>
              )}
            </div>
          </div>
        </div>

        {/* Attribution */}
        <div className="text-center mt-12 text-xs text-rose-400">
          Challenge by <a href="https://www.frontendmentor.io?ref=challenge" className="text-blue-500 hover:underline">Frontend Mentor</a>.
          Coded by <a href="#" className="text-blue-500 hover:underline">Your Name Here</a>.
        </div>
      </div>
    </div>
  );
}